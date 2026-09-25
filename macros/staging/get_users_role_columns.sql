{% macro get_users_role_columns() %}
{% set columns = [
    {"name": "_fivetran_deleted", "datatype": dbt.type_boolean()},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "created_at", "datatype": dbt.type_int()},
    {"name": "created_by", "datatype": dbt.type_string()},
    {"name": "description", "datatype": dbt.type_string()},
    {"name": "id", "datatype": dbt.type_string()},
    {"name": "name", "datatype": dbt.type_string()},
    {"name": "predefined_role", "datatype": dbt.type_boolean()},
    {"name": "resource_type", "datatype": dbt.type_string()},
    {"name": "updated_at", "datatype": dbt.type_int()},
    {"name": "users_id", "datatype": dbt.type_string()},
] %}
{{ return(columns) }}
{% endmacro %}
