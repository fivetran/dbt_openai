-- One row per source relation, day, user, project, model, and product. actor_email/project_name
-- drop when their source table is disabled; disabled entirely if no product table is on.

{{ config(enabled=(openai.openai_enabled_usage_products() | length > 0)) }}

with enterprise_usage as (

    select *
    from {{ ref('int_openai__enterprise_usage_unioned') }}

),

{% if var('openai_using_users', True) %}
users as (

    select *
    from {{ ref('stg_openai__users') }}

),
{% endif %}

{% if var('openai_using_project', True) %}
project as (

    select *
    from {{ ref('stg_openai__project') }}

),
{% endif %}

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['enterprise_usage.source_relation', 'enterprise_usage.date_day', 'enterprise_usage.user_id', 'enterprise_usage.project_id', 'enterprise_usage.model', 'enterprise_usage.product']) }} as enterprise_user_report_id,
        enterprise_usage.source_relation,
        enterprise_usage.date_day,
        enterprise_usage.user_id as actor_user_id,
        {% if var('openai_using_users', True) %}
        users.email as actor_email,
        {% endif %}
        enterprise_usage.project_id,
        {% if var('openai_using_project', True) %}
        project.project_name,
        {% endif %}
        enterprise_usage.model,
        {{ openai.openai_model_family('enterprise_usage.model') }} as model_family,
        {{ openai.openai_model_variant('enterprise_usage.model') }} as model_variant,
        enterprise_usage.product,
        enterprise_usage.quantity,
        enterprise_usage.quantity_unit,
        enterprise_usage.num_model_requests
    from enterprise_usage
    {% if var('openai_using_users', True) %}
    left join users
        on users.user_id = enterprise_usage.user_id
        and users.source_relation = enterprise_usage.source_relation
    {% endif %}
    {% if var('openai_using_project', True) %}
    left join project
        on project.project_id = enterprise_usage.project_id
        and project.source_relation = enterprise_usage.source_relation
    {% endif %}

)

select *
from final
