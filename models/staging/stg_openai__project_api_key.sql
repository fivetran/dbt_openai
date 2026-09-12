{{ config(enabled=var('openai_using_project_api_key', True)) }}

with base as (

    select *
    from {{ ref('stg_openai__project_api_key_tmp') }}

),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_openai__project_api_key_tmp')),
                staging_columns=get_project_api_key_columns()
            )
        }}
        {{ fivetran_utils.apply_source_relation('openai') }}
    from base

),

final as (

    select
        source_relation,
        cast(id as {{ dbt.type_string() }}) as api_key_id,
        name as api_key_name,
        _fivetran_synced
    from fields
    where not coalesce(_fivetran_deleted, false)

)

select *
from final
