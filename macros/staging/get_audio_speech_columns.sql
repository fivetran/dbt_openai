{% macro get_audio_speech_columns() %}
{{ return([
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "api_key_id", "datatype": dbt.type_string()},
    {"name": "character", "datatype": dbt.type_int()},
    {"name": "end_time", "datatype": dbt.type_int()},
    {"name": "input_token", "datatype": dbt.type_int()},
    {"name": "model", "datatype": dbt.type_string()},
    {"name": "num_model_request", "datatype": dbt.type_int()},
    {"name": "object", "datatype": dbt.type_string()},
    {"name": "project_id", "datatype": dbt.type_string()},
    {"name": "start_time", "datatype": dbt.type_int()},
    {"name": "user_id", "datatype": dbt.type_string()},
]) }}
{% endmacro %}
