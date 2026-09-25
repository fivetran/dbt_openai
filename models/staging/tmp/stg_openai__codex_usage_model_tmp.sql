--To disable this model, set the openai__using_codex_usage_model variable within your dbt_project.yml file to False.

{{ config(enabled=var('openai__using_codex_usage_model', True)) }}

{{
    fivetran_utils.union_connections(
        connection_dictionary='openai_sources',
        single_source_name='openai',
        single_table_name='codex_usage_model'
    )
}}
