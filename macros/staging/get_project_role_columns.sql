{% macro get_project_role_columns() %}
{% set columns = [
    {"name": "_fivetran_deleted", "datatype": dbt.type_boolean()},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "description", "datatype": dbt.type_string()},
    {"name": "id", "datatype": dbt.type_string()},
    {"name": "name", "datatype": dbt.type_string()},
    {"name": "predefined_role", "datatype": dbt.type_boolean()},
    {"name": "project_id", "datatype": dbt.type_string()},
    {"name": "resource_type", "datatype": dbt.type_string()},
] %}
{{ return(columns) }}
{% endmacro %}
