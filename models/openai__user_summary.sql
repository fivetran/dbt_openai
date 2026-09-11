-- One row per source relation and user. Optional pieces are entirely omitted from the output
-- (not nulled) when their source table is disabled: no project_user means no project_count/
-- project_names at all; no project means project_count survives from project_user alone but
-- project_names drops; no project_user_role means no project_role_count/project_role_names;
-- no users_role means no org_permission_roles; and if every product feeding
-- int_openai__enterprise_usage_unioned is off, the usage columns drop entirely too — this
-- model itself stays enabled since org role/project membership/roles are independent value.

{% set project_user_enabled = var('openai_using_project_user', True) %}
{% set project_enabled = var('openai_using_project', True) %}
{% set project_user_role_enabled = var('openai_using_project_user_role', True) %}
{% set users_role_enabled = var('openai_using_users_role', True) %}
{% set usage_enabled = openai_enabled_usage_products() | length > 0 %}

{{ config(enabled=var('openai_using_users', True)) }}

{%- set month_start = 'cast(' ~ dbt.date_trunc('month', 'current_date') ~ ' as date)' -%}

with users as (

    select *
    from {{ ref('stg_openai__users') }}

),

{% if project_user_enabled %}
project_user as (

    select *
    from {{ ref('stg_openai__project_user') }}

),

{% if project_enabled %}
project as (

    select *
    from {{ ref('stg_openai__project') }}

),
{% endif %}

distinct_project_membership as (

    select distinct
        project_user.source_relation,
        project_user.user_id,
        project_user.project_id
        {% if project_enabled %}
        , project.project_name
        {% endif %}
    from project_user
    {% if project_enabled %}
    left join project
        on project.project_id = project_user.project_id
        and project.source_relation = project_user.source_relation
    {% endif %}

),

project_membership as (

    select
        source_relation,
        user_id,
        -- distinct_project_membership is already select-distinct on the full tuple, so a
        -- plain count is equivalent to count(distinct ...) here — and Redshift doesn't allow
        -- a distinct aggregate alongside string_agg/listagg in the same query anyway.
        count(project_id) as project_count
        {% if project_enabled %}
        , {{ fivetran_utils.string_agg('project_name', "', '") }} as project_names
        {% endif %}
    from distinct_project_membership
    group by 1, 2

),
{% endif %}

{% if project_user_role_enabled %}
project_user_role as (

    select *
    from {{ ref('stg_openai__project_user_role') }}

),

-- project_user_id is already the user's id (see stg_openai__project_user_role), so this
-- doesn't need project_user as an intermediary.
distinct_project_roles as (

    select distinct
        source_relation,
        project_user_id as user_id,
        role_name
    from project_user_role

),

-- Pre-deduplicated above so both aggregates below can be plain (not distinct) — Redshift
-- doesn't allow a distinct aggregate alongside string_agg/listagg in the same query.
project_roles as (

    select
        source_relation,
        user_id,
        count(role_name) as project_role_count,
        {{ fivetran_utils.string_agg('role_name', "', '") }} as project_role_names
    from distinct_project_roles
    group by 1, 2

),
{% endif %}

{% if users_role_enabled %}
users_role as (

    select *
    from {{ ref('stg_openai__users_role') }}

),

org_permission_roles as (

    select
        source_relation,
        user_id,
        {{ fivetran_utils.string_agg('role_name', "', '") }} as org_permission_roles
    from users_role
    group by 1, 2

),
{% endif %}

{% if usage_enabled %}
enterprise_usage as (

    select *
    from {{ ref('int_openai__enterprise_usage_unioned') }}

),

-- Cost and tokens are not attributed per user (see openai__cost_usage_report), so only
-- token/request usage is rolled up here, all time and for the current calendar month.
-- lifetime_tokens/month_to_date_tokens only sum quantity_unit = 'tokens' rows — quantity is
-- only additive within a single unit, and summing across seconds/characters/tokens together
-- would be meaningless.
usage_rollup as (

    select
        source_relation,
        user_id,
        sum(case when quantity_unit = 'tokens' then quantity end) as lifetime_tokens,
        sum(case when quantity_unit = 'tokens' and date_day >= {{ month_start }} then quantity end) as month_to_date_tokens,
        sum(num_model_requests) as lifetime_num_model_requests,
        sum(case when date_day >= {{ month_start }} then num_model_requests end) as month_to_date_num_model_requests,
        count(distinct date_day) as lifetime_active_days,
        count(distinct case when date_day >= {{ month_start }} then date_day end) as month_to_date_active_days,
        min(date_day) as first_active_date,
        max(date_day) as last_active_date
    from enterprise_usage
    group by 1, 2

),
{% endif %}

final as (

    select
        users.source_relation,
        users.user_id as actor_user_id,
        users.email,
        users.user_name as name,
        users.user_role as role
        {% if users_role_enabled %}
        , org_permission_roles.org_permission_roles
        {% endif %}
        {% if project_user_enabled %}
        , coalesce(project_membership.project_count, 0) as project_count
        {% if project_enabled %}
        , project_membership.project_names
        {% endif %}
        {% endif %}
        {% if project_user_role_enabled %}
        , coalesce(project_roles.project_role_count, 0) as project_role_count
        , project_roles.project_role_names
        {% endif %}
        {% if usage_enabled %}
        , coalesce(usage_rollup.lifetime_tokens, 0) as lifetime_tokens
        , coalesce(usage_rollup.month_to_date_tokens, 0) as month_to_date_tokens
        , coalesce(usage_rollup.lifetime_num_model_requests, 0) as lifetime_num_model_requests
        , coalesce(usage_rollup.month_to_date_num_model_requests, 0) as month_to_date_num_model_requests
        , coalesce(usage_rollup.lifetime_active_days, 0) as lifetime_active_days
        , coalesce(usage_rollup.month_to_date_active_days, 0) as month_to_date_active_days
        , usage_rollup.first_active_date
        , usage_rollup.last_active_date
        {% endif %}
    from users
    {% if users_role_enabled %}
    left join org_permission_roles
        on org_permission_roles.user_id = users.user_id
        and org_permission_roles.source_relation = users.source_relation
    {% endif %}
    {% if project_user_enabled %}
    left join project_membership
        on project_membership.user_id = users.user_id
        and project_membership.source_relation = users.source_relation
    {% endif %}
    {% if project_user_role_enabled %}
    left join project_roles
        on project_roles.user_id = users.user_id
        and project_roles.source_relation = users.source_relation
    {% endif %}
    {% if usage_enabled %}
    left join usage_rollup
        on usage_rollup.user_id = users.user_id
        and usage_rollup.source_relation = users.source_relation
    {% endif %}

)

select *
from final
