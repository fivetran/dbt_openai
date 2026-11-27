{{ config(
    tags="fivetran_validations",
    enabled=(var('fivetran_validation_tests_enabled', false) and var('openai__using_compliance_cost', true))
) }}

-- openai__compliance_cost_report must tie out to the billing lines of every event in the cost log, per unit.
-- Fails if rollback events or negative cost are dropped, if credits and USD are mixed, or if billing stops joining to its events.

with events as (

    select distinct
        source_relation,
        organization_id,
        event_id
    from {{ ref('stg_openai__compliance_cost') }}

),

source_totals as (

    select
        billing.source_relation,
        sum(billing.credits) as credits,
        sum(billing.cost_usd) as cost_usd,
        sum(billing.quantity) as quantity
    from {{ ref('stg_openai__compliance_cost_billing') }} as billing
    inner join events
        on events.source_relation = billing.source_relation
        and events.organization_id = billing.organization_id
        and events.event_id = billing.event_id
    group by 1

),

report_totals as (

    select
        source_relation,
        sum(credits) as credits,
        sum(cost_usd) as cost_usd,
        sum(quantity) as quantity
    from {{ ref('openai__compliance_cost_report') }}
    group by 1

)

select
    source_totals.source_relation,
    source_totals.credits as source_credits,
    report_totals.credits as report_credits,
    source_totals.cost_usd as source_cost_usd,
    report_totals.cost_usd as report_cost_usd,
    source_totals.quantity as source_quantity,
    report_totals.quantity as report_quantity
from source_totals
left join report_totals
    on report_totals.source_relation = source_totals.source_relation
where report_totals.source_relation is null
    or abs(coalesce(source_totals.credits, 0) - coalesce(report_totals.credits, 0)) > 0.0001
    or abs(coalesce(source_totals.cost_usd, 0) - coalesce(report_totals.cost_usd, 0)) > 0.0001
    or abs(coalesce(source_totals.quantity, 0) - coalesce(report_totals.quantity, 0)) > 0.0001
