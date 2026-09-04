-- One row per source relation, day, and user. Per-model/speed credit and token detail is
-- rolled up onto this grain rather than fanned out into one row per model/speed — mirrors
-- claude__code_report, where the same kind of sparse per-model breakdown is summed onto the
-- parent instead of multiplying rows. Still useful with only one of codex_usage/
-- codex_usage_model enabled: codex_usage-only drops the credit/token columns entirely;
-- codex_usage_model-only drops actor_email and the productivity columns entirely, since only
-- codex_usage resolves the email or reports lines/threads/turns.

{% set codex_usage_enabled = var('openai_using_codex_usage', True) %}
{% set codex_usage_model_enabled = var('openai_using_codex_usage_model', True) %}

{{ config(enabled=codex_usage_enabled or codex_usage_model_enabled) }}

with

{% if codex_usage_enabled %}
codex_usage as (

    select *
    from {{ ref('stg_openai__codex_usage') }}

),
{% endif %}

{% if codex_usage_model_enabled %}
codex_usage_model as (

    select *
    from {{ ref('stg_openai__codex_usage_model') }}

),
{% endif %}

-- Neither side alone is guaranteed to carry every (source_relation, day, user) combination,
-- so the grain is built from whichever side(s) actually have rows. codex_usage_model is at
-- (day, user, model, speed) grain, so its contribution here must be de-duplicated down to
-- (day, user) — the outer select distinct, not a plain union all, is what keeps this unique.
spine as (

    select distinct source_relation, usage_started_at, user_id
    from (

        {% if codex_usage_enabled %}
        select source_relation, usage_started_at, user_id
        from codex_usage
        {% endif %}

        {{ 'union all' if codex_usage_enabled and codex_usage_model_enabled }}

        {% if codex_usage_model_enabled %}
        select source_relation, usage_started_at, user_id
        from codex_usage_model
        {% endif %}

    ) as spine_keys

),

{% if codex_usage_model_enabled %}
model_rollup as (

    select
        source_relation,
        usage_started_at,
        user_id,
        count(distinct model) as count_models_used,
        sum(credits) as credits,
        sum(input_tokens) as input_tokens,
        sum(cache_read_tokens) as cache_read_tokens,
        sum(output_tokens) as output_tokens
    from codex_usage_model
    {{ dbt_utils.group_by(n=3) }}

),
{% endif %}

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['spine.source_relation', 'spine.usage_started_at', 'spine.user_id']) }} as code_report_id,
        spine.source_relation,
        cast({{ dbt.date_trunc('day', 'spine.usage_started_at') }} as date) as date_day,
        spine.user_id
        {% if codex_usage_enabled %}
        , codex_usage.actor_email
        , codex_usage.code_attribution_lines_added as count_lines_of_code_added
        , codex_usage.code_attribution_lines_removed as count_lines_of_code_removed
        , codex_usage.total_threads as count_threads
        , codex_usage.total_turns as count_turns
        {% endif %}
        {% if codex_usage_model_enabled %}
        , model_rollup.count_models_used
        , model_rollup.credits
        , model_rollup.input_tokens
        , model_rollup.cache_read_tokens
        , model_rollup.output_tokens
        {% endif %}
    from spine
    {% if codex_usage_enabled %}
    left join codex_usage
        on codex_usage.source_relation = spine.source_relation
        and codex_usage.usage_started_at = spine.usage_started_at
        and codex_usage.user_id = spine.user_id
    {% endif %}
    {% if codex_usage_model_enabled %}
    left join model_rollup
        on model_rollup.source_relation = spine.source_relation
        and model_rollup.usage_started_at = spine.usage_started_at
        and model_rollup.user_id = spine.user_id
    {% endif %}

)

select *
from final
