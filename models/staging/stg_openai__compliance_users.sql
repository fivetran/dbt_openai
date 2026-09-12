{{ config(enabled=var('openai_using_compliance_users', True)) }}

with base as (

    select *
    from {{ ref('stg_openai__compliance_users_tmp') }}

),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_openai__compliance_users_tmp')),
                staging_columns=get_compliance_users_columns()
            )
        }}
        {{ fivetran_utils.apply_source_relation('openai_compliance') }}
    from base

),

final as (

    select
        source_relation,
        cast(id as {{ dbt.type_string() }}) as user_id,
        cast(workspace_id as {{ dbt.type_string() }}) as workspace_id,
        -- Not filtering _fivetran_deleted: offboarded users still need their email attributed to
        -- historical spend in the compliance cost rollup, not dropped. See stg_openai__users.sql.
        lower(email) as email,
        name as user_name,
        role as user_role,
        status as user_status,
        created_at,
        _fivetran_synced
    from fields

)

select *
from final
