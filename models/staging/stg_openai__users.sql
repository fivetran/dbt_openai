with base as (

    select *
    from {{ ref('stg_openai__users_tmp') }}

),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_openai__users_tmp')),
                staging_columns=get_users_columns()
            )
        }}
        {{ fivetran_utils.apply_source_relation('openai') }}
    from base

),

final as (

    select
        source_relation,
        cast(id as {{ dbt.type_string() }}) as user_id,
        email,
        name as user_name,
        role as user_role,
        _fivetran_synced
    -- Not filtering _fivetran_deleted: offboarded users still need their email/name attributed
    -- to historical usage in downstream reports, not dropped.
    from fields

)

select *
from final
