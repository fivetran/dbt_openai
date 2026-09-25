{{ config(enabled=var('openai__using_codex_usage', True)) }}

with base as (

    select *
    from {{ ref('stg_openai__codex_usage_tmp') }}

),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_openai__codex_usage_tmp')),
                staging_columns=get_codex_usage_columns()
            )
        }}
        {{ fivetran_utils.apply_source_relation('openai') }}
    from base

),

final as (

    select
        source_relation,
        cast(start_time as {{ dbt.type_timestamp() }}) as usage_started_at,
        cast(user_id as {{ dbt.type_string() }}) as user_id,
        lower(actor_email) as actor_email,
        cast(code_attribution_lines_added as {{ dbt.type_int() }}) as code_attribution_lines_added,
        cast(code_attribution_lines_removed as {{ dbt.type_int() }}) as code_attribution_lines_removed,
        cast(total_thread as {{ dbt.type_int() }}) as total_threads,
        cast(total_turn as {{ dbt.type_int() }}) as total_turns,
        cast(total_credit as {{ dbt.type_float() }}) as credits,
        cast(total_uncached_text_input_token as {{ dbt.type_int() }}) as input_tokens,
        cast(total_cached_text_input_token as {{ dbt.type_int() }}) as cache_read_tokens,
        cast(total_text_output_token as {{ dbt.type_int() }}) as output_tokens,
        _fivetran_synced
        {{ fivetran_utils.fill_pass_through_columns('openai__codex_usage_passthrough_metrics') }}
    from fields
    where not coalesce(_fivetran_deleted, false)

)

select *
from final
