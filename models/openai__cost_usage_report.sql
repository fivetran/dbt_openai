-- One row per source relation, day, project, and model, plus one org-level row per source
-- relation/day for cost that isn't tied to any project (cost_type = 'other') — either it
-- doesn't break out by model at all, or it's token-type cost the Costs API didn't attribute to
-- a project and that also found no matching completion volume to allocate against. Still
-- useful with only one of cost/completion enabled: completion-only drops the cost/currency
-- columns entirely (usage only); cost-only keeps cost by day/project/model/cost_type, dropping
-- only the token columns, since only completion reports those.
--
-- Cost on `tokens` rows is either used directly (`cost_attribution_method = 'direct'`) when the
-- Costs API already reports a project_id, or inferred (`'allocated'`) by applying an implied
-- per-token rate — derived from the Costs endpoint's unattributed daily spend per model and unit
-- type — to each project's share of that day's token volume. `'unallocated'` marks token cost
-- with no project_id and no matching completion volume to allocate against; `'mixed'` marks a
-- project/model/day where different unit types (input/cache_read/output) resolved differently.

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

    select source_relation, date_day, project_id, model, unit_type, cost_amount, currency_code
    from cost_by_model_day
    where cost_type = 'tokens'
    and project_id is not null

),

-- Cost that isn't tied to any project, carried at the org level instead so this report's total
-- always ties to the source cost table rather than silently dropping anything. Three distinct
-- reasons land here: non-token cost with no project_id, non-token cost the API did tie to a
-- project (kept per-project rather than pooled), and token-type cost with neither a project_id
-- nor a matching completion volume to allocate against.
other_cost as (

    select source_relation, date_day, project_id, cost_amount, currency_code
    from cost_by_model_day
    where cost_type = 'other'

    union all

    select source_relation, date_day, cast(null as {{ dbt.type_string() }}) as project_id, cost_amount, currency_code
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
        {{ dbt_utils.generate_surrogate_key(['attributed.source_relation', 'attributed.date_day', 'attributed.project_id', 'attributed.model']) }} as cost_usage_report_id,
        attributed.source_relation,
        attributed.date_day,
        attributed.project_id,
        {% if project_enabled %}
        project.project_name,
        {% endif %}
        attributed.model,
        {{ openai_model_family('attributed.model') }} as model_family,
        {{ openai_model_variant('attributed.model') }} as model_variant,
        sum(case when attributed.unit_type = 'input' then attributed.token_quantity end) as input_tokens,
        sum(case when attributed.unit_type = 'cache_read' then attributed.token_quantity end) as cache_read_tokens,
        sum(case when attributed.unit_type = 'output' then attributed.token_quantity end) as output_tokens,
        sum(attributed.num_model_requests) as num_model_requests
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
        {{ dbt_utils.generate_surrogate_key(['other_cost_grouped.source_relation', 'other_cost_grouped.date_day', 'other_cost_grouped.project_id']) }} as cost_usage_report_id,
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
        cast(null as {{ dbt.type_int() }}) as num_model_requests,
        'other' as cost_type,
        case when other_cost_grouped.project_id is not null then 'direct' else 'unallocated' end as cost_attribution_method,
        other_cost_grouped.openai_cost,
        other_cost_grouped.currency
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
        {{ dbt_utils.generate_surrogate_key(['cost_by_model_day.source_relation', 'cost_by_model_day.date_day', 'cost_by_model_day.project_id', 'cost_by_model_day.model', 'cost_by_model_day.cost_type']) }} as cost_usage_report_id,
        cost_by_model_day.source_relation,
        cost_by_model_day.date_day,
        cost_by_model_day.project_id,
        {% if project_enabled %}
        project.project_name,
        {% endif %}
        cost_by_model_day.model,
        {{ openai_model_family('cost_by_model_day.model') }} as model_family,
        {{ openai_model_variant('cost_by_model_day.model') }} as model_variant,
        cost_by_model_day.cost_type,
        case when cost_by_model_day.project_id is not null then 'direct' else 'unallocated' end as cost_attribution_method,
        sum(cost_by_model_day.cost_amount) as openai_cost,
        max(cost_by_model_day.currency_code) as currency
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
