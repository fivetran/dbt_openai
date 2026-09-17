{{ config(enabled=var('openai_using_invite', True)) }}

with base as (

    select *
    from {{ ref('stg_openai__invite_tmp') }}

),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_openai__invite_tmp')),
                staging_columns=get_invite_columns()
            )
        }}
        {{ fivetran_utils.apply_source_relation('openai') }}
    from base

),

final as (

    select
        source_relation,
        cast(id as {{ dbt.type_string() }}) as invite_id,
        lower(email) as email,
        role as invited_role,
        status as invite_status,
        _fivetran_synced
    from fields
    where not coalesce(_fivetran_deleted, false)

)

select *
from final
