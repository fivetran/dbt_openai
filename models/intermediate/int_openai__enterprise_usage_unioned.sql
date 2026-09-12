{%- set enabled_products = openai.openai_enabled_usage_products() -%}

{{ config(enabled=(enabled_products | length > 0)) }}

with

{% for product_config in enabled_products %}
{{ product_config.table }} as (

    select *
    from {{ ref('stg_openai__' ~ product_config.table) }}

),
{% endfor %}

-- quantity is only additive within one quantity_unit — tokens, seconds, characters, or null,
-- depending on the product.
unioned as (

    {% for product_config in enabled_products %}
    select
        source_relation,
        cast({{ dbt.date_trunc('day', 'usage_started_at') }} as date) as date_day,
        coalesce(cast(project_id as {{ dbt.type_string() }}), '__none__') as project_id,
        coalesce(cast(user_id as {{ dbt.type_string() }}), '__none__') as user_id,
        {{ "'__none__'" if product_config.no_model is defined else "coalesce(cast(model as " ~ dbt.type_string() ~ "), '__none__')" }} as model,
        '{{ product_config.product }}' as product,
        {{ (product_config.quantity_expr if product_config.quantity_expr else 'cast(null as ' ~ dbt.type_int() ~ ')' ) }} as quantity,
        {{ "'" ~ product_config.quantity_unit ~ "'" if product_config.quantity_unit else "cast(null as " ~ dbt.type_string() ~ ")" }} as quantity_unit,
        {{ product_config.request_col }} as num_model_requests
    from {{ product_config.table }}
    {{ 'union all' if not loop.last }}
    {% endfor %}

),

final as (

    select
        source_relation,
        date_day,
        project_id,
        user_id,
        model,
        product,
        quantity_unit,
        sum(quantity) as quantity,
        sum(num_model_requests) as num_model_requests
    from unioned
    {{ dbt_utils.group_by(n=7) }}

)

select *
from final
