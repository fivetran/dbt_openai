{% macro get_file_search_call_columns() %}
{{ return([
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "_fivetran_id", "datatype": dbt.type_string()},
    {"name": "api_key_id", "datatype": dbt.type_string()},
    {"name": "end_time", "datatype": dbt.type_int()},
    {"name": "num_request", "datatype": dbt.type_int()},
    {"name": "project_id", "datatype": dbt.type_string()},
    {"name": "start_time", "datatype": dbt.type_int()},
    {"name": "user_id", "datatype": dbt.type_string()},
    {"name": "vector_store_id", "datatype": dbt.type_string()},
]) }}
{% endmacro %}
