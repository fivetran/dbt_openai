{{ config(enabled=var('openai_using_cost', True) and var('openai_using_completion', True)) }}

-- Only token cost the Costs API didn't already attribute to a project needs a rate card — rows
-- with a project_id are used directly; "other" (non-token) rows have no model/unit_type to key a rate on.
with cost_by_model_day as (

    select *
    from {{ ref('int_openai__cost_by_model_day') }}
    where cost_type = 'tokens'
    and project_id is null

),

completion_unpivoted as (

    select *
    from {{ ref('int_openai__completion_unpivoted') }}

),

-- Org-wide token volume per day/model/unit_type — the rate denominator. Left joined, not inner:
-- a cost slice may have no matching completion slice, and those get rate_per_token = null instead of being dropped.
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
