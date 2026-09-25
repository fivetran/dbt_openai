{{ config(enabled=var('openai__using_completion', True)) }}

{% set token_unit_types = ['input', 'cache_read', 'output'] %}
{% set passthrough_metrics = var('openai__completion_passthrough_metrics', []) %}

with completion as (

    select *
    from {{ ref('stg_openai__completion') }}

),

with_date as (

    select
        source_relation,
        cast({{ dbt.date_trunc('day', 'usage_started_at') }} as date) as date_day,
        project_id,
        model,
        num_model_requests,
        input_tokens,
        cache_read_tokens,
        output_tokens
        {{ fivetran_utils.persist_pass_through_columns('openai__completion_passthrough_metrics') }}
    from completion

),

-- num_model_requests is carried only on the never-filtered 'input' branch to avoid triple-counting. api_key_id is dropped (summed away) so cost doesn't fan out per key downstream.
unpivoted as (

    {% for token_unit_type in token_unit_types %}
    select
        source_relation,
        date_day,
        project_id,
        model,
        {{ 'num_model_requests' if token_unit_type == 'input' else 'cast(null as ' ~ dbt.type_int() ~ ')' }} as num_model_requests,
        '{{ token_unit_type }}' as token_unit_type,
        {{ token_unit_type }}_tokens as token_quantity
        {% for field in passthrough_metrics %}
        {% set field_name = field.alias if (field is mapping and field.alias) else (field.name if field is mapping else field) %}
        , {{ field_name if token_unit_type == 'input' else 'cast(null as ' ~ dbt.type_float() ~ ')' }} as {{ field_name }}
        {% endfor %}
    from with_date
    {% if token_unit_type != 'input' %}
    where {{ token_unit_type }}_tokens > 0
    {% endif %}
    {{ 'union all' if not loop.last }}
    {% endfor %}

),

final as (

    select
        source_relation,
        date_day,
        project_id,
        model,
        token_unit_type,
        sum(token_quantity) as token_quantity,
        sum(num_model_requests) as num_model_requests
        {{ fivetran_utils.persist_pass_through_columns('openai__completion_passthrough_metrics', transform='sum') }}
    from unpivoted
    {{ dbt_utils.group_by(n=5) }}

)

select *
from final
