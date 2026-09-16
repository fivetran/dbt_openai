{% macro get_project_user_columns() %}
{% set columns = [
    {"name": "_fivetran_deleted", "datatype": dbt.type_boolean()},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "id", "datatype": dbt.type_string()},
    {"name": "project_id", "datatype": dbt.type_string()},
] %}
{{ return(columns) }}
{% endmacro %}
