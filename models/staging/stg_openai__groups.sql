{{ config(enabled=var('openai_using_groups', True)) }}

with base as (

    select *
    from {{ ref('stg_openai__groups_tmp') }}

),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_openai__groups_tmp')),
                staging_columns=get_groups_columns()
            )
        }}
        {{ fivetran_utils.apply_source_relation('openai') }}
    from base

),

final as (

    select
        source_relation,
        cast(id as {{ dbt.type_string() }}) as group_id,
        name as group_name,
        _fivetran_synced
    from fields
    where not coalesce(_fivetran_deleted, false)

)

select *
from final
