{{ config(enabled=var('openai_using_codex_usage_model', True)) }}

with base as (

    select *
    from {{ ref('stg_openai__codex_usage_model_tmp') }}

),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_openai__codex_usage_model_tmp')),
                staging_columns=get_codex_usage_model_columns()
            )
        }}
        {{ fivetran_utils.apply_source_relation('openai') }}
    from base

),

final as (

    select
        source_relation,
        cast(codex_usage_start_time as {{ dbt.type_timestamp() }}) as usage_started_at,
        cast(codex_usage_user_id as {{ dbt.type_string() }}) as user_id,
        model,
        speed,
        {{ dbt.safe_cast('credit', dbt.type_float()) }} as credits,
        {{ dbt.safe_cast('uncached_text_input_token', dbt.type_int()) }} as input_tokens,
        {{ dbt.safe_cast('cached_text_input_token', dbt.type_int()) }} as cache_read_tokens,
        {{ dbt.safe_cast('text_output_token', dbt.type_int()) }} as output_tokens,
        _fivetran_synced
    from fields
    where not coalesce(_fivetran_deleted, false)

)

select *
from final
