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
        code_attribution_lines_added,
        code_attribution_lines_removed,
        total_thread as total_threads,
        total_turn as total_turns,
        _fivetran_synced
    from fields
    where not coalesce(_fivetran_deleted, false)

)

select *
from final
