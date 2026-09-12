--To disable this model, set the openai_using_compliance_cost variable within your dbt_project.yml file to False.

{{ config(enabled=var('openai_using_compliance_cost', True)) }}

{{
    fivetran_utils.union_connections(
        connection_dictionary='openai_compliance_sources',
        single_source_name='openai_compliance',
        single_table_name='costs_organization_log'
    )
}}
