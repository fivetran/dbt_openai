{% macro openai_regex_matches(column, pattern) %}
    {{ return(adapter.dispatch('openai_regex_matches', 'openai')(column, pattern)) }}
{% endmacro %}

{% macro default__openai_regex_matches(column, pattern) %}
    {%- if target.type in ['postgres', 'redshift'] -%}
        ({{ column }} ~ '{{ pattern }}')
    {%- elif target.type in ['spark', 'databricks'] -%}
        ({{ column }} rlike '{{ pattern }}')
    {%- elif target.type == 'bigquery' -%}
        regexp_contains({{ column }}, '{{ pattern }}')
    {%- elif target.type == 'duckdb' -%}
        regexp_matches({{ column }}, '{{ pattern }}')
    {%- else -%}
        regexp_like({{ column }}, '{{ pattern }}')
    {%- endif -%}
{% endmacro %}
