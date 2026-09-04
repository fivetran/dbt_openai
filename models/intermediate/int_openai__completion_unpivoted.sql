{{ config(enabled=var('openai_using_completion', True)) }}

{% set unit_types = ['input', 'cache_read', 'output'] %}

with completion as (

    select *
    from {{ ref('stg_openai__completion') }}

),

with_date as (

    select
        source_relation,
        {{ dbt.date_trunc('day', 'usage_started_at') }} as date_day,
        project_id,
        api_key_id,
        model,
        num_model_requests,
        input_tokens,
        cache_read_tokens,
        output_tokens
    from completion

),

-- num_model_requests is one count per source row (not per unit type), so it is only
-- carried on the 'input' branch below — summing it downstream would otherwise
-- triple-count requests once the row fans out across up to three unit types.
unpivoted as (

    {% for unit_type in unit_types %}
    select
        source_relation,
        date_day,
        project_id,
        api_key_id,
        model,
        {{ 'num_model_requests' if unit_type == 'input' else 'cast(null as ' ~ dbt.type_int() ~ ')' }} as num_model_requests,
        '{{ unit_type }}' as unit_type,
        {{ unit_type }}_tokens as token_quantity
    from with_date
    where {{ unit_type }}_tokens > 0
    {{ 'union all' if not loop.last }}
    {% endfor %}

),

final as (

    select
        source_relation,
        date_day,
        project_id,
        api_key_id,
        model,
        unit_type,
        sum(token_quantity) as token_quantity,
        sum(num_model_requests) as num_model_requests
    from unpivoted
    {{ dbt_utils.group_by(n=6) }}

)

select *
from final
