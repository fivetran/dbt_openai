{% macro get_compliance_cost_columns() %}
{% set columns = [
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "actor_id", "datatype": dbt.type_string()},
    {"name": "actor_type", "datatype": dbt.type_string()},
    {"name": "client", "datatype": dbt.type_string()},
    {"name": "day", "datatype": dbt.type_timestamp()},
    {"name": "event_id", "datatype": dbt.type_string()},
    {"name": "hour", "datatype": dbt.type_int()},
    {"name": "identity_agent_id", "datatype": dbt.type_string()},
    {"name": "identity_agent_name", "datatype": dbt.type_string()},
    {"name": "identity_user_id", "datatype": dbt.type_string()},
    {"name": "image_output_token", "datatype": dbt.type_float()},
    {"name": "model", "datatype": dbt.type_string()},
    {"name": "organization_id", "datatype": dbt.type_string()},
    {"name": "principal_id", "datatype": dbt.type_string()},
    {"name": "principal_type", "datatype": dbt.type_string()},
    {"name": "product", "datatype": dbt.type_string()},
    {"name": "reasoning", "datatype": dbt.type_string()},
    {"name": "service_tier", "datatype": dbt.type_string()},
    {"name": "surface", "datatype": dbt.type_string()},
    {"name": "text_cached_input_token", "datatype": dbt.type_float()},
    {"name": "text_input_token", "datatype": dbt.type_float()},
    {"name": "text_output_token", "datatype": dbt.type_float()},
    {"name": "type", "datatype": dbt.type_string()},
] %}
{{ fivetran_utils.add_pass_through_columns(columns, var('openai__compliance_cost_passthrough_metrics', [])) }}
{{ return(columns) }}
{% endmacro %}
