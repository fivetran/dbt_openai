{% macro get_compliance_costs_log_file_columns() %}
{% set columns = [
    {"name": "_fivetran_deleted", "datatype": dbt.type_boolean()},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "end_time", "datatype": dbt.type_timestamp()},
    {"name": "file_name", "datatype": dbt.type_string()},
    {"name": "file_sha256", "datatype": dbt.type_string()},
    {"name": "file_size", "datatype": dbt.type_int()},
    {"name": "id", "datatype": dbt.type_string()},
    {"name": "organization_id", "datatype": dbt.type_string()},
] %}
{{ return(columns) }}
{% endmacro %}
