{% macro get_codex_usage_columns() %}
{% set columns = [
    {"name": "_fivetran_deleted", "datatype": dbt.type_boolean()},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "actor_email", "datatype": dbt.type_string()},
    {"name": "actor_type", "datatype": dbt.type_string()},
    {"name": "code_attribution_lines_added", "datatype": dbt.type_int()},
    {"name": "code_attribution_lines_removed", "datatype": dbt.type_int()},
    {"name": "end_time", "datatype": dbt.type_int()},
    {"name": "start_time", "datatype": dbt.type_timestamp()},
    {"name": "total_cached_text_input_token", "datatype": dbt.type_int()},
    {"name": "total_credit", "datatype": dbt.type_float()},
    {"name": "total_text_output_token", "datatype": dbt.type_int()},
    {"name": "total_text_total_token", "datatype": dbt.type_int()},
    {"name": "total_thread", "datatype": dbt.type_int()},
    {"name": "total_turn", "datatype": dbt.type_int()},
    {"name": "total_uncached_text_input_token", "datatype": dbt.type_int()},
    {"name": "user_id", "datatype": dbt.type_string()},
    {"name": "workspace_id", "datatype": dbt.type_string()},
] %}
{{ fivetran_utils.add_pass_through_columns(columns, var('openai__codex_usage_passthrough_metrics', [])) }}
{{ return(columns) }}
{% endmacro %}
