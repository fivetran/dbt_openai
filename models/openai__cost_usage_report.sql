-- One row per source relation, day, project, and model, plus one org-level row per source
-- relation/day for cost that can't be attributed to a project (cost_type = 'other') — either
-- it doesn't break out by model at all, or it's token-type cost with no matching completion
-- volume for its day/model/unit_type. Still useful with only one of cost/completion enabled: completion-only drops the cost/
-- currency columns entirely (usage only); cost-only drops the project and token columns
-- entirely (cost by day/model/cost_type only, since only completion reports a project).

{% set cost_enabled = var('openai_using_cost', True) %}
{% set completion_enabled = var('openai_using_completion', True) %}

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

{% if cost_enabled and completion_enabled %}
cost_rate_card as (

    select *
    from {{ ref('int_openai__cost_rate_card') }}

),

-- Cost that can't be attributed to a project, carried at the org level instead so this
-- report's total always ties to the source cost table rather than silently dropping
-- anything. Two distinct reasons land here: non-token cost that doesn't break out by model
-- at all (e.g. aggregate feature charges like "Assistants API"), and token-type cost that
-- found no matching completion volume for its day/model/unit_type — e.g. the Costs API using
-- a coarser model name than completion, or cost finalizing before usage lands.
other_cost as (

    select source_relation, date_day, cost_amount, currency_code
    from cost_by_model_day
    where cost_type = 'other'

    union all

    select source_relation, date_day, cost_amount, currency_code
    from cost_rate_card
    where rate_per_token is null

),

other_cost_grouped as (

    select
        source_relation,
        date_day,
        sum(cost_amount) as openai_cost,
        max(currency_code) as currency
    from other_cost
    {{ dbt_utils.group_by(n=2) }}

),
{% endif %}

{% if completion_enabled %}
{% if var('openai_using_project', True) %}
project as (

    select *
    from {{ ref('stg_openai__project') }}

),
{% endif %}

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
        , completion_unpivoted.token_quantity * cost_rate_card.rate_per_token as openai_cost
        , cost_rate_card.currency_code
        {% endif %}
    from completion_unpivoted
    {% if cost_enabled %}
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
        {% if var('openai_using_project', True) %}
        project.project_name,
        {% endif %}
        attributed.model,
        {{ openai_model_family('attributed.model') }} as model_family,
        sum(case when attributed.unit_type = 'input' then attributed.token_quantity end) as input_tokens,
        sum(case when attributed.unit_type = 'cache_read' then attributed.token_quantity end) as cache_read_tokens,
        sum(case when attributed.unit_type = 'output' then attributed.token_quantity end) as output_tokens,
        sum(attributed.num_model_requests) as num_model_requests
        {% if cost_enabled %}
        , 'tokens' as cost_type
        , sum(attributed.openai_cost) as openai_cost
        -- a day/model slice is always billed in one currency in practice; max() is just a
        -- safe way to carry it through this aggregation.
        , max(attributed.currency_code) as currency
        {% endif %}
    from attributed
    {% if var('openai_using_project', True) %}
    left join project
        on project.project_id = attributed.project_id
        and project.source_relation = attributed.source_relation
    {% endif %}
    {{ dbt_utils.group_by(n=(7 if var('openai_using_project', True) else 6)) }}

    {% if cost_enabled %}
    union all

    select
        {{ dbt_utils.generate_surrogate_key(['other_cost_grouped.source_relation', 'other_cost_grouped.date_day']) }} as cost_usage_report_id,
        other_cost_grouped.source_relation,
        other_cost_grouped.date_day,
        cast(null as {{ dbt.type_string() }}) as project_id,
        {% if var('openai_using_project', True) %}
        cast(null as {{ dbt.type_string() }}) as project_name,
        {% endif %}
        cast(null as {{ dbt.type_string() }}) as model,
        cast(null as {{ dbt.type_string() }}) as model_family,
        cast(null as {{ dbt.type_int() }}) as input_tokens,
        cast(null as {{ dbt.type_int() }}) as cache_read_tokens,
        cast(null as {{ dbt.type_int() }}) as output_tokens,
        cast(null as {{ dbt.type_int() }}) as num_model_requests,
        'other' as cost_type,
        other_cost_grouped.openai_cost,
        other_cost_grouped.currency
    from other_cost_grouped
    {% endif %}

)
{% else %}
-- cost-only mode: no completion, so no project dimension and no token detail — cost by day,
-- model, and cost_type only (model and unit_type are null on 'other', non-token rows).
final as (

    select
        {{ dbt_utils.generate_surrogate_key(['cost_by_model_day.source_relation', 'cost_by_model_day.date_day', 'cost_by_model_day.model', 'cost_by_model_day.cost_type']) }} as cost_usage_report_id,
        cost_by_model_day.source_relation,
        cost_by_model_day.date_day,
        cost_by_model_day.model,
        {{ openai_model_family('cost_by_model_day.model') }} as model_family,
        cost_by_model_day.cost_type,
        sum(cost_by_model_day.cost_amount) as openai_cost,
        max(cost_by_model_day.currency_code) as currency
    from cost_by_model_day
    {{ dbt_utils.group_by(n=6) }}

)
{% endif %}

select *
from final
