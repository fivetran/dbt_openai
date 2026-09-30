{% macro null_passthrough_metrics(pass_through_variable) %}
    {{ return(adapter.dispatch('null_passthrough_metrics', 'openai')(pass_through_variable)) }}
{% endmacro %}

{#- Emits a null placeholder per passthrough field, so a branch missing real values still lines up column-for-column with one that has them. -#}
{% macro default__null_passthrough_metrics(pass_through_variable) %}
{% for field in var(pass_through_variable, []) %}
    {% set field_name = field.alias if (field is mapping and field.alias) else (field.name if field is mapping else field) %}
    , cast(null as {{ dbt.type_float() }}) as {{ field_name }}
{% endfor %}
{% endmacro %}
