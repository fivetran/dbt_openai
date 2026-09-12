{% macro get_users_columns() %}
{{ return([
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "added_at", "datatype": dbt.type_string()},
    {"name": "email", "datatype": dbt.type_string()},
    {"name": "id", "datatype": dbt.type_string()},
    {"name": "name", "datatype": dbt.type_string()},
    {"name": "object", "datatype": dbt.type_string()},
    {"name": "role", "datatype": dbt.type_string()},
]) }}
{% endmacro %}
