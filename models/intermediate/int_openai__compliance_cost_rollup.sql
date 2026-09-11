-- Disabled by default, not yet wired into any report (overlaps with codex_usage for the codex
-- product). No restatement dedup needed: cost/billing keys have no log-file id, so a later sync just overwrites the row.

{% set email_enabled = var('openai_using_compliance_users', False) %}

{{ config(enabled=var('openai_using_compliance_cost', False)) }}

with cost_events as (

    select *
    from {{ ref('stg_openai__compliance_cost') }}

),

billing as (

    select *
    from {{ ref('stg_openai__compliance_cost_billing') }}

),

{% if email_enabled %}
compliance_users as (

    select *
    from {{ ref('stg_openai__compliance_users') }}

),
{% endif %}

final as (

    select
        cost_events.source_relation,
        cost_events.organization_id,
        cost_events.date_day,
        cost_events.user_id
        {% if email_enabled %}
        , coalesce(compliance_users.email, '__none__') as email
        {% endif %}
        ,
        coalesce(cost_events.product, '__none__') as product,
        coalesce(cost_events.surface, '__none__') as surface,
        coalesce(cost_events.client, '__none__') as client,
        coalesce(cost_events.model, '__none__') as model,
        coalesce(cost_events.service_tier, '__none__') as service_tier,
        coalesce(cost_events.reasoning, '__none__') as reasoning,
        billing.sku,
        billing.quantity_unit,
        billing.cost_unit,
        -- quantity is only additive within a single quantity_unit (tokens, counts, duration_s,
        -- hours, gib_hours all appear across different SKUs), so it must stay grouped by unit.
        sum(billing.quantity) as quantity,
        sum(billing.credits) as credits,
        sum(billing.estimated_cost_usd_amount) as estimated_cost_usd_amount,
        max(billing.estimated_cost_usd_currency) as estimated_cost_usd_currency
        {{ fivetran_utils.persist_pass_through_columns('openai__compliance_cost_billing_passthrough_metrics', identifier='billing', transform='sum') }}
        -- compliance_cost_passthrough_metrics (event-level) isn't wired in: the billing join fans
        -- one event out across its SKU lines, so summing it here would multiply the value.
    from cost_events
    inner join billing
        on billing.event_id = cost_events.event_id
        and billing.organization_id = cost_events.organization_id
        and billing.source_relation = cost_events.source_relation
    {% if email_enabled %}
    left join compliance_users
        on compliance_users.user_id = cost_events.user_id
        and compliance_users.source_relation = cost_events.source_relation
    {% endif %}
    {{ dbt_utils.group_by(n=(14 if email_enabled else 13)) }}

)

select *
from final
