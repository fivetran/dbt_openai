{{ config(enabled=var('openai_using_web_search_call', True)) }}

with base as (

    select *
    from {{ ref('stg_openai__web_search_call_tmp') }}

),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_openai__web_search_call_tmp')),
                staging_columns=get_web_search_call_columns()
            )
        }}
        {{ fivetran_utils.apply_source_relation('openai') }}
    from base

),

final as (

    select
        source_relation,
        cast(_fivetran_id as {{ dbt.type_string() }}) as web_search_call_id,
        cast(project_id as {{ dbt.type_string() }}) as project_id,
        cast(user_id as {{ dbt.type_string() }}) as user_id,
        cast(api_key_id as {{ dbt.type_string() }}) as api_key_id,
        model,
        cast(num_request as {{ dbt.type_int() }}) as num_requests,
        cast(num_model_request as {{ dbt.type_int() }}) as num_model_requests,
        cast({{ dbt.dateadd('second', 'start_time', "cast('1970-01-01' as timestamp)") }} as {{ dbt.type_timestamp() }}) as usage_started_at,
        _fivetran_synced
    from fields
    where not coalesce(_fivetran_deleted, false)

)

select *
from final
