-- Daily ChatGPT Enterprise (Compliance Platform) spend by user, product, and SKU. Only its `codex` rows overlap openai__code_report, and from a cost angle, not productivity — summing both double-counts.

{% set email_enabled = var('openai__using_compliance_users', True) %}

{{ config(enabled=var('openai__using_compliance_cost', True)) }}

with cost_events_raw as (

    select *
    from {{ ref('stg_openai__compliance_cost') }}

),

log_file as (

    select *
    from {{ ref('stg_openai__compliance_costs_log_file') }}

),

billing_raw as (

    select *
    from {{ ref('stg_openai__compliance_cost_billing') }}

),

-- OpenAI re-emits a still-open event with a cumulative count in every later log file; only the latest end_time is a correct read (costs_log_id desc just tiebreaks equal end_times).
ranked_cost_events as (

    select
        cost_events_raw.*,
        row_number() over (
            partition by cost_events_raw.organization_id, cost_events_raw.event_id
                {{ fivetran_utils.partition_by_source_relation(package_name='openai', alias='cost_events_raw') }}
            order by log_file.end_time desc, cost_events_raw.costs_log_id desc
        ) as file_recency
    from cost_events_raw
    left join log_file
        on log_file.source_relation = cost_events_raw.source_relation
        and log_file.costs_log_id = cost_events_raw.costs_log_id

),

cost_events as (

    select *
    from ranked_cost_events
    where file_recency = 1

),

-- Scoped to cost_events' winning costs_log_id, so stale billing lines aren't pulled in alongside the current event.
billing as (

    select billing_raw.*
    from billing_raw
    inner join cost_events
        on cost_events.source_relation = billing_raw.source_relation
        and cost_events.organization_id = billing_raw.organization_id
        and cost_events.event_id = billing_raw.event_id
        and cost_events.costs_log_id = billing_raw.costs_log_id

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
        , compliance_users.email
        {% endif %}
        ,
        cost_events.product,
        cost_events.surface,
        cost_events.client,
        cost_events.model,
        cost_events.service_tier,
        cost_events.reasoning,
        billing.sku,
        billing.quantity_unit,
        billing.cost_unit,
        -- quantity is only additive within a single quantity_unit (different SKUs use tokens, counts, duration_s, hours, gib_hours), so it must stay grouped by unit.
        sum(billing.quantity) as quantity,
        sum(billing.credits) as credits,
        sum(billing.estimated_cost_usd_amount) as estimated_cost_usd_amount,
        max(billing.estimated_cost_usd_currency) as estimated_cost_usd_currency
        {{ fivetran_utils.persist_pass_through_columns('openai__compliance_cost_billing_passthrough_metrics', identifier='billing', transform='sum') }}
        -- compliance_cost_passthrough_metrics (event-level) isn't wired in: the billing join fans it out per SKU, so summing here would multiply the value.
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
