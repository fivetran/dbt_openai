{{ config(enabled=var('openai__using_cost', True)) }}

with cost as (

    select *
    from {{ ref('stg_openai__cost') }}

),

parsed as (

    select
        source_relation,
        cast({{ dbt.date_trunc('day', 'usage_started_at') }} as date) as date_day,
        project_id,
        replace(line_item, 'evals | ', '') as cleaned_line_item,
        cost_amount,
        currency_code
        {{ fivetran_utils.persist_pass_through_columns('openai__cost_passthrough_metrics') }}
    from cost

),

typed as (

    select
        source_relation,
        date_day,
        project_id,
        trim({{ dbt.split_part('cleaned_line_item', "','", 1) }}) as model,
        case
            when lower(cleaned_line_item) like '%, cached input%' then 'cache_read'
            when lower(cleaned_line_item) like '%, cache writes%' then 'cache_write'
            when lower(cleaned_line_item) like '%, output%' then 'output'
            when lower(cleaned_line_item) like '%, input%' then 'input'
        end as token_unit_type,
        cost_amount,
        currency_code
        {{ fivetran_utils.persist_pass_through_columns('openai__cost_passthrough_metrics') }}
    from parsed

),

-- Line items that parsed into a model + token unit type. cache_write's missing completion counterpart is handled by a full outer join in openai__cost_usage_report, not here.
token_cost as (

    select
        source_relation,
        date_day,
        project_id,
        model,
        token_unit_type,
        'tokens' as cost_type,
        cost_amount,
        currency_code
        {{ fivetran_utils.persist_pass_through_columns('openai__cost_passthrough_metrics') }}
    from typed
    where token_unit_type is not null

),

-- feature/aggregate charges that don't break out by model (e.g. "Assistants API") — kept so
-- this report's total ties to the source cost table instead of silently dropping them.
other_cost as (

    select
        source_relation,
        date_day,
        project_id,
        cast(null as {{ dbt.type_string() }}) as model,
        cast(null as {{ dbt.type_string() }}) as token_unit_type,
        'other' as cost_type,
        cost_amount,
        currency_code
        {{ fivetran_utils.persist_pass_through_columns('openai__cost_passthrough_metrics') }}
    from typed
    where token_unit_type is null

),

unioned as (

    select *
    from token_cost
    union all
    select *
    from other_cost

),

final as (

    select
        source_relation,
        date_day,
        -- null when the Costs API didn't attribute a project — cost_usage_report allocates those
        -- via the rate card; a populated project_id here is used directly, no allocation.
        project_id,
        model,
        token_unit_type,
        cost_type,
        sum(cost_amount) as cost_amount,
        -- a day/project/model/token_unit_type/cost_type slice is always billed in one currency in
        -- practice; max() is just a safe way to carry it through this aggregation.
        max(currency_code) as currency_code
        {{ fivetran_utils.persist_pass_through_columns('openai__cost_passthrough_metrics', transform='sum') }}
    from unioned
    {{ dbt_utils.group_by(n=6) }}

)

select *
from final
