{{ config(enabled=var('openai_using_codex_usage', True)) }}

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
        {{ dbt.safe_cast('code_attribution_lines_added', dbt.type_int()) }} as code_attribution_lines_added,
        {{ dbt.safe_cast('code_attribution_lines_removed', dbt.type_int()) }} as code_attribution_lines_removed,
        {{ dbt.safe_cast('total_thread', dbt.type_int()) }} as total_threads,
        {{ dbt.safe_cast('total_turn', dbt.type_int()) }} as total_turns,
        {{ dbt.safe_cast('total_credit', dbt.type_float()) }} as credits,
        {{ dbt.safe_cast('total_uncached_text_input_token', dbt.type_int()) }} as input_tokens,
        {{ dbt.safe_cast('total_cached_text_input_token', dbt.type_int()) }} as cache_read_tokens,
        {{ dbt.safe_cast('total_text_output_token', dbt.type_int()) }} as output_tokens,
        _fivetran_synced
    from fields
    where not coalesce(_fivetran_deleted, false)

)

select *
from final
