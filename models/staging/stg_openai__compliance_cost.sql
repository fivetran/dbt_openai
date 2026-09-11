{{ config(enabled=var('openai_using_compliance_cost', False)) }}

with base as (

    select *
    from {{ ref('stg_openai__compliance_cost_tmp') }}

),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_openai__compliance_cost_tmp')),
                staging_columns=get_compliance_cost_columns()
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
        type as event_type,
        cast({{ dbt.date_trunc('day', 'day') }} as date) as date_day,
        hour,
        identity_user_id as user_id,
        product,
        surface,
        client,
        model,
        service_tier,
        reasoning,
        text_input_token as input_tokens,
        text_cached_input_token as cache_read_tokens,
        text_output_token as output_tokens,
        image_output_token as image_output_tokens,
        _fivetran_synced
    from fields

)

select *
from final
