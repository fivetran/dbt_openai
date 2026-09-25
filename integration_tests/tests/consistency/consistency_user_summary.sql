{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

-- Excluded: month_to_date_* (depends on current_date) and unordered string_agg columns vary run to run regardless of real data changes.

with prod as (
    select {{ dbt_utils.star(from=ref('openai__user_summary'), except=["month_to_date_tokens", "month_to_date_num_model_requests", "month_to_date_active_days", "project_names", "project_role_names", "org_permission_roles"]) }}
    from {{ target.schema }}_openai_prod.openai__user_summary
),

dev as (
    select {{ dbt_utils.star(from=ref('openai__user_summary'), except=["month_to_date_tokens", "month_to_date_num_model_requests", "month_to_date_active_days", "project_names", "project_role_names", "org_permission_roles"]) }}
    from {{ target.schema }}_openai_dev.openai__user_summary
),

prod_not_in_dev as (
    select * from prod
    except distinct
    select * from dev
),

dev_not_in_prod as (
    select * from dev
    except distinct
    select * from prod
),

final as (
    select
        *,
        'from prod' as source
    from prod_not_in_dev

    union all

    select
        *,
        'from dev' as source
    from dev_not_in_prod
)

select *
from final
