{% macro get_compliance_cost_billing_columns() %}
{% set columns = [
    {"name": "_fivetran_deleted", "datatype": dbt.type_boolean()},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "cost_unit", "datatype": dbt.type_string()},
    {"name": "cost_value", "datatype": dbt.type_float()},
    {"name": "costs_log_id", "datatype": dbt.type_string()},
    {"name": "estimated_cost_usd_amount", "datatype": dbt.type_float()},
    {"name": "estimated_cost_usd_currency", "datatype": dbt.type_string()},
    {"name": "event_id", "datatype": dbt.type_string()},
    {"name": "organization_id", "datatype": dbt.type_string()},
    {"name": "quantity_unit", "datatype": dbt.type_string()},
    {"name": "quantity_value", "datatype": dbt.type_float()},
    {"name": "sku", "datatype": dbt.type_string()},
] %}
{{ fivetran_utils.add_pass_through_columns(columns, var('openai__compliance_cost_billing_passthrough_metrics', [])) }}
{{ return(columns) }}
{% endmacro %}
