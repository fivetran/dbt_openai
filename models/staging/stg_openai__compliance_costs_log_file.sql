-- Catalog of the log files OpenAI's Compliance cost log is delivered in. Purely infrastructure
-- for openai__compliance_cost_report's restatement dedup (see that model) — not intended
-- to be queried on its own.

{{ config(enabled=var('openai_using_compliance_cost', True)) }}

with base as (

    select *
    from {{ ref('stg_openai__compliance_costs_log_file_tmp') }}

),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_openai__compliance_costs_log_file_tmp')),
                staging_columns=get_compliance_costs_log_file_columns()
            )
        }}
        {{ fivetran_utils.apply_source_relation('openai') }}
    from base

),

final as (

    select
        source_relation,
        cast(id as {{ dbt.type_string() }}) as costs_log_id,
        cast(organization_id as {{ dbt.type_string() }}) as organization_id,
        cast(end_time as {{ dbt.type_timestamp() }}) as end_time,
        file_name,
        file_size,
        file_sha256,
        _fivetran_synced
    from fields

)

select *
from final
