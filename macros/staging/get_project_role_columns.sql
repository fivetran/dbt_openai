{% macro get_project_role_columns() %}
{{ return([
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "description", "datatype": dbt.type_string()},
    {"name": "id", "datatype": dbt.type_string()},
    {"name": "name", "datatype": dbt.type_string()},
    {"name": "predefined_role", "datatype": "boolean"},
    {"name": "project_id", "datatype": dbt.type_string()},
    {"name": "resource_type", "datatype": dbt.type_string()},
]) }}
{% endmacro %}
