-- One row per source relation, day, user, project, model, and product. project_name drops when
-- its source table is disabled; disabled entirely if no product table is on.

{{ config(enabled=(openai.openai_enabled_usage_products() | length > 0)) }}

with enterprise_usage as (

    select *
    from {{ ref('int_openai__enterprise_usage_unioned') }}

),

users as (

    select *
    from {{ ref('stg_openai__users') }}

),

{% if var('openai__using_project', True) %}
project as (

    select *
    from {{ ref('stg_openai__project') }}

),
{% endif %}

final as (

    select
        enterprise_usage.source_relation,
        enterprise_usage.date_day,
        enterprise_usage.user_id as actor_user_id,
        users.email as actor_email,
        enterprise_usage.project_id,
        {% if var('openai__using_project', True) %}
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
    left join users
        on users.user_id = enterprise_usage.user_id
        and users.source_relation = enterprise_usage.source_relation
    {% if var('openai__using_project', True) %}
    left join project
        on project.project_id = enterprise_usage.project_id
        and project.source_relation = enterprise_usage.source_relation
    {% endif %}

)

select *
from final
