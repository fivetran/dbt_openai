-- One row per source relation, day, and user. Per-model/speed detail rolls up onto this grain
-- rather than fanning out; credits/tokens come from codex_usage when enabled, else a codex_usage_model rollup — either table alone is still useful.

{% set codex_usage_enabled = var('openai_using_codex_usage', True) %}
{% set codex_usage_model_enabled = var('openai_using_codex_usage_model', True) %}

{{ config(enabled=codex_usage_enabled or codex_usage_model_enabled) }}

with

{% if codex_usage_enabled %}
-- date_trunc'd defensively here rather than trusting usage_started_at is always midnight — a
-- day/user grain must join and de-dupe on the same truncated value everywhere below.
codex_usage as (

    select
        *,
        cast({{ dbt.date_trunc('day', 'usage_started_at') }} as date) as date_day
    from {{ ref('stg_openai__codex_usage') }}

),
{% endif %}

{% if codex_usage_model_enabled %}
codex_usage_model as (

    select
        *,
        cast({{ dbt.date_trunc('day', 'usage_started_at') }} as date) as date_day
    from {{ ref('stg_openai__codex_usage_model') }}

),
{% endif %}

-- Grain comes from whichever side(s) have rows; codex_usage_model is per (day, user, model,
-- speed), so select distinct (not plain union all) keeps this de-duplicated to (day, user).
spine as (

    select
        distinct source_relation,
        date_day,
        user_id
    from (

        {% if codex_usage_enabled %}
        select
            source_relation,
            date_day,
            user_id
        from codex_usage
        {% endif %}

        {{ 'union all' if codex_usage_enabled and codex_usage_model_enabled }}

        {% if codex_usage_model_enabled %}
        select
            source_relation,
            date_day,
            user_id
        from codex_usage_model
        {% endif %}

    ) as spine_keys

),

{% if codex_usage_model_enabled %}
model_rollup as (

    select
        source_relation,
        date_day,
        user_id,
        count(distinct model) as count_models_used,
        sum(credits) as credits,
        sum(input_tokens) as input_tokens,
        sum(cache_read_tokens) as cache_read_tokens,
        sum(output_tokens) as output_tokens
        {{ fivetran_utils.persist_pass_through_columns('openai__codex_usage_model_passthrough_metrics', transform='sum') }}
    from codex_usage_model
    {{ dbt_utils.group_by(n=3) }}

),
{% endif %}

final as (

    select
        spine.source_relation,
        spine.date_day,
        spine.user_id
        {% if codex_usage_enabled %}
        , codex_usage.actor_email
        , coalesce(codex_usage.code_attribution_lines_added, 0) as count_lines_of_code_added
        , coalesce(codex_usage.code_attribution_lines_removed, 0) as count_lines_of_code_removed
        , coalesce(codex_usage.total_threads, 0) as count_threads
        , coalesce(codex_usage.total_turns, 0) as count_turns
        {% endif %}
        {% if codex_usage_model_enabled %}
        , coalesce(model_rollup.count_models_used, 0) as count_models_used
        {{ fivetran_utils.persist_pass_through_columns('openai__codex_usage_model_passthrough_metrics', identifier='model_rollup') }}
        {% endif %}
        {% if codex_usage_enabled %}
        , coalesce(codex_usage.credits, 0) as credits
        , coalesce(codex_usage.input_tokens, 0) as input_tokens
        , coalesce(codex_usage.cache_read_tokens, 0) as cache_read_tokens
        , coalesce(codex_usage.output_tokens, 0) as output_tokens
        {{ fivetran_utils.persist_pass_through_columns('openai__codex_usage_passthrough_metrics', identifier='codex_usage') }}
        {% elif codex_usage_model_enabled %}
        , coalesce(model_rollup.credits, 0) as credits
        , coalesce(model_rollup.input_tokens, 0) as input_tokens
        , coalesce(model_rollup.cache_read_tokens, 0) as cache_read_tokens
        , coalesce(model_rollup.output_tokens, 0) as output_tokens
        {% endif %}
    from spine
    {% if codex_usage_enabled %}
    left join codex_usage
        on codex_usage.source_relation = spine.source_relation
        and codex_usage.date_day = spine.date_day
        and codex_usage.user_id = spine.user_id
    {% endif %}
    {% if codex_usage_model_enabled %}
    left join model_rollup
        on model_rollup.source_relation = spine.source_relation
        and model_rollup.date_day = spine.date_day
        and model_rollup.user_id = spine.user_id
    {% endif %}

)

select *
from final
