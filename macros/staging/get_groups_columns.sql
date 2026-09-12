{% macro get_groups_columns() %}
{{ return([
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "created_at", "datatype": dbt.type_int()},
    {"name": "id", "datatype": dbt.type_string()},
    {"name": "is_scim_managed", "datatype": "boolean"},
    {"name": "name", "datatype": dbt.type_string()},
]) }}
{% endmacro %}
