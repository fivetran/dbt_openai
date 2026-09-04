{{ config(enabled=var('openai_using_cost', True) and var('openai_using_completion', True)) }}

-- only token-based cost can be rate-carded — "other" (non-token, e.g. aggregate feature
-- charges) rows have no model/unit_type to key a rate on and are surfaced separately in
-- openai__cost_usage_report instead.
with cost_by_model_day as (

    select *
    from {{ ref('int_openai__cost_by_model_day') }}
    where cost_type = 'tokens'

),

completion_unpivoted as (

    select *
    from {{ ref('int_openai__completion_unpivoted') }}

),

-- org-wide token volume per day/model/unit_type, across every project — the denominator
-- for the implied per-token rate. The Costs endpoint reports spend at this same grain but
-- without a project breakdown, so a project's cost is inferred from its share of this total.
-- Left joined below rather than inner joined: a day/model/unit_type slice of cost isn't
-- guaranteed to have a matching completion slice (the Costs API can use a coarser model name
-- than completion, or finalize before usage lands), and dropping that cost silently would
-- reintroduce the same reconciliation gap non-token cost has — rate_per_token is null on
-- those rows, and openai__cost_usage_report carries them at the org level instead.
token_totals as (

    select
        source_relation,
        date_day,
        model,
        unit_type,
        sum(token_quantity) as token_quantity
    from completion_unpivoted
    {{ dbt_utils.group_by(n=4) }}

),

final as (

    select
        cost_by_model_day.source_relation,
        cost_by_model_day.date_day,
        cost_by_model_day.model,
        cost_by_model_day.unit_type,
        cost_by_model_day.cost_amount,
        cost_by_model_day.currency_code,
        token_totals.token_quantity as total_token_quantity,
        {{ dbt_utils.safe_divide('cost_by_model_day.cost_amount', 'token_totals.token_quantity') }} as rate_per_token
    from cost_by_model_day
    left join token_totals
        on token_totals.source_relation = cost_by_model_day.source_relation
        and token_totals.date_day = cost_by_model_day.date_day
        and token_totals.model = cost_by_model_day.model
        and token_totals.unit_type = cost_by_model_day.unit_type

)

select *
from final
