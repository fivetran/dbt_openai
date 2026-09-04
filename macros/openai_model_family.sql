{% macro openai_model_family(model_column) %}
    case
        when {{ model_column }} is null then null
        when lower({{ model_column }}) like 'codex-mini%' then 'o4'
        when lower({{ model_column }}) like 'gpt-4o%' then 'gpt-4o'
        when lower({{ model_column }}) like 'gpt-4.1%' then 'gpt-4.1'
        when lower({{ model_column }}) like 'gpt-3.5%' then 'gpt-3.5'
        when lower({{ model_column }}) like 'gpt-4%' then 'gpt-4'
        when lower({{ model_column }}) like 'gpt-5%' then 'gpt-5'
        when lower({{ model_column }}) like 'o1%' then 'o1'
        when lower({{ model_column }}) like 'o3%' then 'o3'
        when lower({{ model_column }}) like 'o4%' then 'o4'
        when lower({{ model_column }}) like 'text-embedding%' then 'text-embedding'
        when lower({{ model_column }}) like 'whisper%' then 'whisper'
        when lower({{ model_column }}) like 'tts%' then 'tts'
        when lower({{ model_column }}) like 'dall-e%' then 'dall-e'
        else 'unclassified'
    end
{% endmacro %}
