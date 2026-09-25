{{ config(enabled=var('openai__using_completion', True)) }}

with base as (

    select *
    from {{ ref('stg_openai__completion_tmp') }}

),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_openai__completion_tmp')),
                staging_columns=get_completion_columns()
            )
        }}
        {{ fivetran_utils.apply_source_relation('openai') }}
    from base

),

final as (

    select
        source_relation,
        cast(_fivetran_id as {{ dbt.type_string() }}) as completion_id,
        cast(project_id as {{ dbt.type_string() }}) as project_id,
        cast(user_id as {{ dbt.type_string() }}) as user_id,
        cast(api_key_id as {{ dbt.type_string() }}) as api_key_id,
        model,
        cast(input_token as {{ dbt.type_int() }}) as input_tokens,
        cast(input_cached_token as {{ dbt.type_int() }}) as cache_read_tokens,
        cast(output_token as {{ dbt.type_int() }}) as output_tokens,
        cast(num_model_request as {{ dbt.type_int() }}) as num_model_requests,
        cast({{ dbt.dateadd('second', 'start_time', "cast('1970-01-01' as timestamp)") }} as {{ dbt.type_timestamp() }}) as usage_started_at,
        _fivetran_synced
        {{ fivetran_utils.fill_pass_through_columns('openai__completion_passthrough_metrics') }}
    from fields
    where not coalesce(_fivetran_deleted, false)

)

select *
from final
