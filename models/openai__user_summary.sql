-- One row per source relation and user. Optional column groups are entirely omitted (not
-- nulled) when their source table is disabled — see each column's description.

{% set project_user_enabled = var('openai_using_project_user', True) %}
{% set project_enabled = var('openai_using_project', True) %}
{% set project_user_role_enabled = var('openai_using_project_user_role', True) %}
{% set users_role_enabled = var('openai_using_users_role', True) %}
{% set project_api_key_enabled = var('openai_using_project_api_key', True) %}
{% set invite_enabled = var('openai_using_invite', True) %}
{% set usage_enabled = openai.openai_enabled_usage_products() | length > 0 %}

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
        -- distinct_project_membership is already select-distinct on the full tuple, so plain
        -- count equals count(distinct...) — Redshift disallows a distinct aggregate alongside string_agg anyway.
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
        {{ fivetran_utils.string_agg('distinct role_name', "', '") }} as org_permission_roles
    from users_role
    group by 1, 2

),
{% endif %}

{% if project_api_key_enabled %}
project_api_key as (

    select *
    from {{ ref('stg_openai__project_api_key') }}

),

-- Service-account-owned keys have no user_id and don't count toward any user's total.
api_key_counts as (

    select
        source_relation,
        user_id,
        count(api_key_id) as api_key_count
    from project_api_key
    where user_id is not null
    group by 1, 2

),
{% endif %}

{% if invite_enabled %}
invite as (

    select *
    from {{ ref('stg_openai__invite') }}

),

-- An email can have more than one invite (e.g. re-invited after expiring); only the most
-- recent one per email is relevant to this user's current status.
ranked_invite as (

    select
        source_relation,
        email,
        invite_status,
        invited_at,
        row_number() over (partition by source_relation, email order by invited_at desc) as invite_rank
    from invite

),

latest_invite as (

    select
        source_relation,
        email,
        invite_status as latest_invite_status,
        invited_at as latest_invited_at
    from ranked_invite
    where invite_rank = 1

),
{% endif %}

{% if usage_enabled %}
enterprise_usage as (

    select *
    from {{ ref('int_openai__enterprise_usage_unioned') }}

),

-- Cost/tokens aren't attributed per user, so only token/request usage rolls up here.
-- lifetime/month_to_date_tokens sum quantity_unit = 'tokens' only, since quantity isn't comparable across units.
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
        users.user_role as role,
        users._fivetran_deleted as is_user_deleted
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
        {% if project_api_key_enabled %}
        , coalesce(api_key_counts.api_key_count, 0) as api_key_count
        {% endif %}
        {% if invite_enabled %}
        , latest_invite.latest_invite_status
        , latest_invite.latest_invited_at
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
    {% if project_api_key_enabled %}
    left join api_key_counts
        on api_key_counts.user_id = users.user_id
        and api_key_counts.source_relation = users.source_relation
    {% endif %}
    {% if invite_enabled %}
    left join latest_invite
        on latest_invite.email = users.email
        and latest_invite.source_relation = users.source_relation
    {% endif %}
    {% if usage_enabled %}
    left join usage_rollup
        on usage_rollup.user_id = users.user_id
        and usage_rollup.source_relation = users.source_relation
    {% endif %}

)

select *
from final
