{% macro get_cost_columns() %}
{% set columns = [
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "_fivetran_id", "datatype": dbt.type_string()},
    {"name": "amount_currency", "datatype": dbt.type_string()},
    {"name": "amount_value", "datatype": dbt.type_string()},
    {"name": "end_time", "datatype": dbt.type_int()},
    {"name": "line_item", "datatype": dbt.type_string()},
    {"name": "object", "datatype": dbt.type_string()},
    {"name": "organization_id", "datatype": dbt.type_string()},
    {"name": "project_id", "datatype": dbt.type_string()},
    {"name": "start_time", "datatype": dbt.type_int()},
] %}
{{ fivetran_utils.add_pass_through_columns(columns, var('openai__cost_passthrough_metrics', [])) }}
{{ return(columns) }}
{% endmacro %}
