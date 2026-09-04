{{ config(enabled=var('openai_using_users', True)) }}

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
    from fields
    where not coalesce(_fivetran_deleted, false)

)

select *
from final
