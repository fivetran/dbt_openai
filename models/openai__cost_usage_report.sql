-- One row per source relation, day, project, and model, plus an org-level 'other' row for cost
-- not tied to a project. cost_attribution_method marks 'direct' (API-attributed), 'allocated' (rate-carded), 'unallocated', or 'mixed'.

{% set cost_enabled = var('openai_using_cost', True) %}
{% set completion_enabled = var('openai_using_completion', True) %}
{% set project_enabled = var('openai_using_project', True) %}

{{ config(enabled=cost_enabled or completion_enabled) }}

with

{% if completion_enabled %}
completion_unpivoted as (

    select *
    from {{ ref('int_openai__completion_unpivoted') }}

),
{% endif %}

{% if cost_enabled %}
cost_by_model_day as (

    select *
    from {{ ref('int_openai__cost_by_model_day') }}

),
{% endif %}

{% if project_enabled %}
project as (

    select *
    from {{ ref('stg_openai__project') }}

),
{% endif %}

{% if cost_enabled and completion_enabled %}
cost_rate_card as (

    select *
    from {{ ref('int_openai__cost_rate_card') }}

),

-- Token-type cost the Costs API already tied to a project — used directly, with no rate-card
-- allocation involved.
directly_attributed_cost as (

    select
        source_relation,
        date_day,
        project_id,
        model,
        unit_type,
        cost_amount,
        currency_code
        {{ fivetran_utils.persist_pass_through_columns('openai__cost_passthrough_metrics') }}
    from cost_by_model_day
    where cost_type = 'tokens'
    and project_id is not null

),

-- Cost not tied to any project, carried at the org level so this report's total always ties to
-- the source cost table — covers non-token cost (with or without a project_id) and unallocated token cost.
other_cost as (

    select 
        source_relation,
        date_day,
        project_id,
        cost_amount,
        currency_code
    from cost_by_model_day
    where cost_type = 'other'

    union all

    select 
        source_relation,
        date_day,
        cast(null as {{ dbt.type_string() }}) as project_id,
        cost_amount,
        currency_code
    from cost_rate_card
    where rate_per_token is null

),

other_cost_grouped as (

    select
        source_relation,
        date_day,
        project_id,
        sum(cost_amount) as openai_cost,
        max(currency_code) as currency
    from other_cost
    {{ dbt_utils.group_by(n=3) }}

),
{% endif %}

{% if completion_enabled %}
attributed as (

    select
        completion_unpivoted.source_relation,
        completion_unpivoted.date_day,
        completion_unpivoted.project_id,
        completion_unpivoted.model,
        completion_unpivoted.unit_type,
        completion_unpivoted.token_quantity,
        completion_unpivoted.num_model_requests
        {{ fivetran_utils.persist_pass_through_columns('openai__completion_passthrough_metrics', identifier='completion_unpivoted') }}
        {% if cost_enabled %}
        , coalesce(
            directly_attributed_cost.cost_amount,
            completion_unpivoted.token_quantity * cost_rate_card.rate_per_token
            ) as openai_cost
        , coalesce(directly_attributed_cost.currency_code, cost_rate_card.currency_code) as currency_code
        , case
            when directly_attributed_cost.cost_amount is not null then 'direct'
            when cost_rate_card.rate_per_token is not null then 'allocated'
            end as cost_attribution_method
        -- cost passthrough metrics only apply to directly-attributed rows — a custom field on a
        -- redistributed org-level charge has no per-project meaning, so it's left null on allocated rows.
        {{ fivetran_utils.persist_pass_through_columns('openai__cost_passthrough_metrics', identifier='directly_attributed_cost') }}
        {% endif %}
    from completion_unpivoted
    {% if cost_enabled %}
    left join directly_attributed_cost
        on directly_attributed_cost.source_relation = completion_unpivoted.source_relation
        and directly_attributed_cost.date_day = completion_unpivoted.date_day
        and directly_attributed_cost.project_id = completion_unpivoted.project_id
        and directly_attributed_cost.model = completion_unpivoted.model
        and directly_attributed_cost.unit_type = completion_unpivoted.unit_type
    left join cost_rate_card
        on cost_rate_card.source_relation = completion_unpivoted.source_relation
        and cost_rate_card.date_day = completion_unpivoted.date_day
        and cost_rate_card.model = completion_unpivoted.model
        and cost_rate_card.unit_type = completion_unpivoted.unit_type
    {% endif %}

),

final as (

    select
        attributed.source_relation,
        attributed.date_day,
        attributed.project_id,
        {% if project_enabled %}
        project.project_name,
        {% endif %}
        attributed.model,
        {{ openai.openai_model_family('attributed.model') }} as model_family,
        {{ openai.openai_model_variant('attributed.model') }} as model_variant,
        sum(case when attributed.unit_type = 'input' then attributed.token_quantity end) as input_tokens,
        sum(case when attributed.unit_type = 'cache_read' then attributed.token_quantity end) as cache_read_tokens,
        sum(case when attributed.unit_type = 'output' then attributed.token_quantity end) as output_tokens,
        sum(attributed.num_model_requests) as num_model_requests
        {{ fivetran_utils.persist_pass_through_columns('openai__completion_passthrough_metrics', identifier='attributed', transform='sum') }}
        {% if cost_enabled %}
        , 'tokens' as cost_type
        , case
            when count(distinct attributed.cost_attribution_method) > 1 then 'mixed'
            else max(attributed.cost_attribution_method)
            end as cost_attribution_method
        , sum(attributed.openai_cost) as openai_cost
        -- a day/project/model slice is always billed in one currency in practice; max() is just
        -- a safe way to carry it through this aggregation.
        , max(attributed.currency_code) as currency
        {{ fivetran_utils.persist_pass_through_columns('openai__cost_passthrough_metrics', identifier='attributed', transform='sum') }}
        {% endif %}
    from attributed
    {% if project_enabled %}
    left join project
        on project.project_id = attributed.project_id
        and project.source_relation = attributed.source_relation
    {% endif %}
    {{ dbt_utils.group_by(n=(8 if project_enabled else 7)) }}

    {% if cost_enabled %}
    union all

    select
        other_cost_grouped.source_relation,
        other_cost_grouped.date_day,
        other_cost_grouped.project_id,
        {% if project_enabled %}
        project_other.project_name,
        {% endif %}
        cast(null as {{ dbt.type_string() }}) as model,
        cast(null as {{ dbt.type_string() }}) as model_family,
        cast(null as {{ dbt.type_string() }}) as model_variant,
        cast(null as {{ dbt.type_int() }}) as input_tokens,
        cast(null as {{ dbt.type_int() }}) as cache_read_tokens,
        cast(null as {{ dbt.type_int() }}) as output_tokens,
        cast(null as {{ dbt.type_int() }}) as num_model_requests
        {{ openai.null_passthrough_metrics('openai__completion_passthrough_metrics') }}
        , 'other' as cost_type,
        case when other_cost_grouped.project_id is not null then 'direct' else 'unallocated' end as cost_attribution_method,
        other_cost_grouped.openai_cost,
        other_cost_grouped.currency
        {{ openai.null_passthrough_metrics('openai__cost_passthrough_metrics') }}
    from other_cost_grouped
    {% if project_enabled %}
    left join project as project_other
        on project_other.project_id = other_cost_grouped.project_id
        and project_other.source_relation = other_cost_grouped.source_relation
    {% endif %}
    {% endif %}

)
{% else %}
-- cost-only mode: no completion, so no token detail — cost by day, project, model, and
-- cost_type only (project_id/model are null on 'other', non-project/non-model rows).
final as (

    select
        cost_by_model_day.source_relation,
        cost_by_model_day.date_day,
        cost_by_model_day.project_id,
        {% if project_enabled %}
        project.project_name,
        {% endif %}
        cost_by_model_day.model,
        {{ openai.openai_model_family('cost_by_model_day.model') }} as model_family,
        {{ openai.openai_model_variant('cost_by_model_day.model') }} as model_variant,
        cost_by_model_day.cost_type,
        case when cost_by_model_day.project_id is not null then 'direct' else 'unallocated' end as cost_attribution_method,
        sum(cost_by_model_day.cost_amount) as openai_cost,
        max(cost_by_model_day.currency_code) as currency
        {{ fivetran_utils.persist_pass_through_columns('openai__cost_passthrough_metrics', identifier='cost_by_model_day', transform='sum') }}
    from cost_by_model_day
    {% if project_enabled %}
    left join project
        on project.project_id = cost_by_model_day.project_id
        and project.source_relation = cost_by_model_day.source_relation
    {% endif %}
    {{ dbt_utils.group_by(n=(10 if project_enabled else 9)) }}

)
{% endif %}

select *
from final
