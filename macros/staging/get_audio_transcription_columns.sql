{% macro get_audio_transcription_columns() %}
{{ return([
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "api_key_id", "datatype": dbt.type_string()},
    {"name": "end_time", "datatype": dbt.type_int()},
    {"name": "model", "datatype": dbt.type_string()},
    {"name": "num_model_request", "datatype": dbt.type_int()},
    {"name": "object", "datatype": dbt.type_string()},
    {"name": "project_id", "datatype": dbt.type_string()},
    {"name": "second", "datatype": dbt.type_int()},
    {"name": "start_time", "datatype": dbt.type_int()},
    {"name": "user_id", "datatype": dbt.type_string()},
]) }}
{% endmacro %}
