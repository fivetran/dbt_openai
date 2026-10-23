{{ config(enabled=var('openai__using_cost', True)) }}

with cost as (

    select *
    from {{ ref('stg_openai__cost') }}

),

{% set label = dbt.split_part('line_item', "' | '", 1) %}
{% set first_word = dbt.split_part('lower(trim(' ~ label ~ '))', "' '", 1) %}

parsed as (

    select
        source_relation,
        cast({{ dbt.date_trunc('day', 'usage_started_at') }} as date) as date_day,
        project_id,
        -- Strip '<label> | ' prefixes from tier-based line items.
        -- 'evals | ' and 'web search tool calls | ' are features, not tiers; strip prefix but keep tier = 'default'.
        case
            when lower(line_item) like '% | %'
                and lower(line_item) not like 'evals | %'
                and lower(line_item) not like 'web search tool calls | %'
                then {{ first_word }} || '-tier'
            else 'default'
        end as service_tier,
        case
            when lower(line_item) like '% | %'
                then trim({{ dbt.split_part('line_item', "' | '", 2) }})
            else line_item
        end as cleaned_line_item,
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
        service_tier,
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
        service_tier,
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
        'default' as service_tier,
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
        service_tier,
        token_unit_type,
        cost_type,
        sum(cost_amount) as cost_amount,
        -- a day/project/model/service_tier/token_unit_type/cost_type slice is always billed in one currency in
        -- practice; max() is just a safe way to carry it through this aggregation.
        max(currency_code) as currency_code
        {{ fivetran_utils.persist_pass_through_columns('openai__cost_passthrough_metrics', transform='sum') }}
    from unioned
    {{ dbt_utils.group_by(n=7) }}

)

select *
from final
