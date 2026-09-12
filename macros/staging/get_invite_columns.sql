{% macro get_invite_columns() %}
{{ return([
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "accepted_at", "datatype": dbt.type_int()},
    {"name": "email", "datatype": dbt.type_string()},
    {"name": "expires_at", "datatype": dbt.type_int()},
    {"name": "id", "datatype": dbt.type_string()},
    {"name": "invited_at", "datatype": dbt.type_int()},
    {"name": "role", "datatype": dbt.type_string()},
    {"name": "status", "datatype": dbt.type_string()},
]) }}
{% endmacro %}
