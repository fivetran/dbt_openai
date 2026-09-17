--To disable this model, set the openai_using_project_api_key variable within your dbt_project.yml file to False.

{{ config(enabled=var('openai_using_project_api_key', True)) }}

{{
    fivetran_utils.union_connections(
        connection_dictionary='openai_sources',
        single_source_name='openai',
        single_table_name='project_api_key'
    )
}}
