{# Infers labels from names, so future numeric GPT and o-series versions work without extending a model list. #}
{% macro _openai_model_parts(model_column) %}
    {% set normalized = 'lower(trim(' ~ model_column ~ '))' %}
    {% set base_model %}
        case when {{ normalized }} like 'ft:%'
            then {{ dbt.split_part(normalized, "':'", 2) }}
            else {{ normalized }} end
    {% endset %}
    {# Strips trailing YYYY-MM-DD snapshot suffix #}
    {% set undated_model = "regexp_replace(" ~ base_model ~ ", '-[0-9]{4}-[0-9]{2}-[0-9]{2}$', '')" %}
    {% set first_segment = dbt.split_part(undated_model, "'-'", 1) %}
    {% set second_segment = dbt.split_part(undated_model, "'-'", 2) %}
    {% set named_prefixes = [
        'text-embedding', 'whisper', 'tts', 'dall-e', 'codex',
        'gpt-image', 'gpt-realtime', 'gpt-audio', 'omni-moderation', 'text-moderation'
    ] %}
    {% set family %}
        case
            when {{ first_segment }} = 'gpt'
                and {{ openai.openai_regex_matches(second_segment, '^[0-9]+([.][0-9]+)?[a-z]?$') }}
                then {{ dbt.concat(["'gpt-'", second_segment]) }}
            when {{ openai.openai_regex_matches(first_segment, '^o[0-9]+$') }}
                then {{ first_segment }}
            {% for prefix in named_prefixes %}
            when {{ undated_model }} = '{{ prefix }}'
                or {{ undated_model }} like '{{ prefix }}-%' then '{{ prefix }}'
            {% endfor %}
            else cast(null as {{ dbt.type_string() }})
        end
    {% endset %}
    {{ return({'base_model': base_model, 'undated_model': undated_model, 'family': family}) }}
{% endmacro %}

{% macro openai_model_family(model_column) %}
    {{ return(adapter.dispatch('openai_model_family', 'openai')(model_column)) }}
{% endmacro %}

{% macro default__openai_model_family(model_column) %}
    {% set parts = openai._openai_model_parts(model_column) %}
    case
        when {{ model_column }} is null then null
        {# Overrides match normalized base models exactly, including dated suffixes.
           Escape literal quotes; overrides are never interpreted as patterns. #}
        {% for override in var('openai_model_family_overrides', []) %}
        when {{ parts.base_model }} = '{{ override.model | trim | lower | replace("'", "''") }}'
            then '{{ override.family | replace("'", "''") }}'
        {% endfor %}
        else coalesce({{ parts.family }}, {{ model_column }})
    end
{% endmacro %}

{% macro openai_model_variant(model_column) %}
    {{ return(adapter.dispatch('openai_model_variant', 'openai')(model_column)) }}
{% endmacro %}

{% macro default__openai_model_variant(model_column) %}
    {% set parts = openai._openai_model_parts(model_column) %}
    case when {{ parts.family }} is not null then
        nullif(substring({{ parts.undated_model }}, length({{ parts.family }}) + 2,
            length({{ parts.undated_model }})), '')
        else cast(null as {{ dbt.type_string() }})
    end
{% endmacro %}
