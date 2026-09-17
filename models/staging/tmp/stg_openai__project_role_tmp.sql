--To disable this model, set the openai_using_project_role variable within your dbt_project.yml file to False.

{{ config(enabled=var('openai_using_project_role', True)) }}

{{
    fivetran_utils.union_connections(
        connection_dictionary='openai_sources',
        single_source_name='openai',
        single_table_name='project_role'
    )
}}
