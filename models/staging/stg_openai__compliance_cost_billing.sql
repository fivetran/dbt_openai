{{ config(enabled=var('openai__using_compliance_cost', True)) }}

with base as (

    select *
    from {{ ref('stg_openai__compliance_cost_billing_tmp') }}

),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_openai__compliance_cost_billing_tmp')),
                staging_columns=get_compliance_cost_billing_columns()
            )
        }}
        {{ fivetran_utils.apply_source_relation('openai') }}
    from base

),

final as (

    select
        source_relation,
        cast(event_id as {{ dbt.type_string() }}) as event_id,
        cast(organization_id as {{ dbt.type_string() }}) as organization_id,
        cast(costs_log_id as {{ dbt.type_string() }}) as costs_log_id,
        sku,
        quantity_unit,
        cast(quantity_value as {{ dbt.type_float() }}) as quantity,
        cost_unit,
        cast(cost_value as {{ dbt.type_float() }}) as credits,
        cast(estimated_cost_usd_amount as {{ dbt.type_float() }}) as estimated_cost_usd_amount,
        estimated_cost_usd_currency,
        _fivetran_synced
        {{ fivetran_utils.fill_pass_through_columns('openai__compliance_cost_billing_passthrough_metrics') }}
    from fields

)

select *
from final
