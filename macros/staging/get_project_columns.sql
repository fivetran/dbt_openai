{% macro get_project_columns() %}
{% set columns = [
    {"name": "_fivetran_deleted", "datatype": dbt.type_boolean()},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "archived_at", "datatype": dbt.type_int()},
    {"name": "created_at", "datatype": dbt.type_int()},
    {"name": "id", "datatype": dbt.type_string()},
    {"name": "name", "datatype": dbt.type_string()},
    {"name": "object", "datatype": dbt.type_string()},
    {"name": "status", "datatype": dbt.type_string()},
] %}
{{ return(columns) }}
{% endmacro %}
