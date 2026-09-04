{% macro get_project_user_columns() %}
{{ return([
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "id", "datatype": dbt.type_string()},
    {"name": "project_id", "datatype": dbt.type_string()},
]) }}
{% endmacro %}
