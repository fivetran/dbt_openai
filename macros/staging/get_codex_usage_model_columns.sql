{% macro get_codex_usage_model_columns() %}
{% set columns = [
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "cached_text_input_token", "datatype": dbt.type_int()},
    {"name": "codex_usage_start_time", "datatype": dbt.type_timestamp()},
    {"name": "codex_usage_user_id", "datatype": dbt.type_string()},
    {"name": "credit", "datatype": dbt.type_float()},
    {"name": "index", "datatype": dbt.type_int()},
    {"name": "model", "datatype": dbt.type_string()},
    {"name": "speed", "datatype": dbt.type_string()},
    {"name": "text_output_token", "datatype": dbt.type_int()},
    {"name": "text_total_token", "datatype": dbt.type_int()},
    {"name": "uncached_text_input_token", "datatype": dbt.type_int()},
] %}
{{ fivetran_utils.add_pass_through_columns(columns, var('openai__codex_usage_model_passthrough_metrics', [])) }}
{{ return(columns) }}
{% endmacro %}
