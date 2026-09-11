{{ config(enabled=var('openai_using_compliance_cost', False)) }}

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
        {{ fivetran_utils.apply_source_relation('openai_compliance') }}
    from base

),

final as (

    select
        source_relation,
        event_id,
        organization_id,
        sku,
        quantity_unit,
        quantity_value as quantity,
        cost_unit,
        cost_value as credits,
        estimated_cost_usd_amount,
        estimated_cost_usd_currency,
        _fivetran_synced
    from fields

)

select *
from final
