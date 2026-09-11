{{ config(enabled=var('openai_using_cost', True)) }}

with base as (

    select *
    from {{ ref('stg_openai__cost_tmp') }}

),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_openai__cost_tmp')),
                staging_columns=get_cost_columns()
            )
        }}
        {{ fivetran_utils.apply_source_relation('openai') }}
    from base

),

final as (

    select
        source_relation,
        cast(_fivetran_id as {{ dbt.type_string() }}) as cost_id,
        cast(project_id as {{ dbt.type_string() }}) as project_id,
        line_item,
        cast(amount_value as {{ dbt.type_float() }}) as cost_amount,
        amount_currency as currency_code,
        cast({{ dbt.dateadd('second', 'start_time', "cast('1970-01-01' as timestamp)") }} as {{ dbt.type_timestamp() }}) as usage_started_at,
        _fivetran_synced
    from fields
    where not coalesce(_fivetran_deleted, false)

)

select *
from final
