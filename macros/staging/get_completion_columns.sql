{% macro get_completion_columns() %}
{{ return([
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "_fivetran_id", "datatype": dbt.type_string()},
    {"name": "api_key_id", "datatype": dbt.type_string()},
    {"name": "batch", "datatype": "boolean"},
    {"name": "end_time", "datatype": dbt.type_int()},
    {"name": "input_audio_token", "datatype": dbt.type_int()},
    {"name": "input_cached_token", "datatype": dbt.type_int()},
    {"name": "input_token", "datatype": dbt.type_int()},
    {"name": "model", "datatype": dbt.type_string()},
    {"name": "num_model_request", "datatype": dbt.type_int()},
    {"name": "object", "datatype": dbt.type_string()},
    {"name": "output_audio_token", "datatype": dbt.type_int()},
    {"name": "output_token", "datatype": dbt.type_int()},
    {"name": "project_id", "datatype": dbt.type_string()},
    {"name": "service_tier", "datatype": dbt.type_string()},
    {"name": "start_time", "datatype": dbt.type_int()},
    {"name": "user_id", "datatype": dbt.type_string()},
]) }}
{% endmacro %}
