--To disable this model, set the openai_using_compliance_users variable within your dbt_project.yml file to False.

{{ config(enabled=var('openai_using_compliance_users', False)) }}

{{
    fivetran_utils.union_connections(
        connection_dictionary='openai_compliance_sources',
        single_source_name='openai_compliance',
        single_table_name='users'
    )
}}
