{% macro get_project_api_key_columns() %}
{{ return([
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "created_at", "datatype": dbt.type_int()},
    {"name": "id", "datatype": dbt.type_string()},
    {"name": "last_used_at", "datatype": dbt.type_int()},
    {"name": "name", "datatype": dbt.type_string()},
    {"name": "owner_type", "datatype": dbt.type_string()},
    {"name": "project_id", "datatype": dbt.type_string()},
    {"name": "redacted_value", "datatype": dbt.type_string()},
    {"name": "service_account_id", "datatype": dbt.type_string()},
    {"name": "user_id", "datatype": dbt.type_string()},
]) }}
{% endmacro %}
