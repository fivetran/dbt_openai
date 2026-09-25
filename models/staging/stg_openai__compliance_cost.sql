{{ config(enabled=var('openai_using_compliance_cost', True)) }}

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
        {{ fivetran_utils.apply_source_relation('openai') }}
    from base

),

final as (

    select
        source_relation,
        cast(event_id as {{ dbt.type_string() }}) as event_id,
        cast(organization_id as {{ dbt.type_string() }}) as organization_id,
        cast(costs_log_id as {{ dbt.type_string() }}) as costs_log_id,
        type as event_type,
        cast({{ dbt.date_trunc('day', 'day') }} as date) as date_day,
        cast(hour as {{ dbt.type_int() }}) as hour,
        cast(identity_user_id as {{ dbt.type_string() }}) as user_id,
        product,
        surface,
        client,
        model,
        service_tier,
        reasoning,
        cast(text_input_token as {{ dbt.type_int() }}) as input_tokens,
        cast(text_cached_input_token as {{ dbt.type_int() }}) as cache_read_tokens,
        cast(text_output_token as {{ dbt.type_int() }}) as output_tokens,
        cast(image_output_token as {{ dbt.type_int() }}) as image_output_tokens,
        _fivetran_synced
        {{ fivetran_utils.fill_pass_through_columns('openai__compliance_cost_passthrough_metrics') }}
    from fields

)

select *
from final
