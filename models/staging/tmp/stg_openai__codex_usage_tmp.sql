--To disable this model, set the openai__using_codex_usage variable within your dbt_project.yml file to False.

{{ config(enabled=var('openai__using_codex_usage', True)) }}

{% if var('openai_union_schemas', []) | length > 0 or var('openai_union_databases', []) | length > 0 %}

{{
    fivetran_utils.union_data(
        table_identifier='codex_usage', 
        database_variable='openai_database', 
        schema_variable='openai_schema', 
        default_database=target.database,
        default_schema='openai',
        default_variable='codex_usage',
        union_schema_variable='openai_union_schemas',
        union_database_variable='openai_union_databases'
    )
}}

{% else %}

{{
    fivetran_utils.union_connections(
        connection_dictionary='openai_sources',
        single_source_name='openai',
        single_table_name='codex_usage'
    )
}}

{% endif %}