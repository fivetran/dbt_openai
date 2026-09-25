--To disable this model, set the openai__using_audio_speech variable within your dbt_project.yml file to False.

{{ config(enabled=var('openai__using_audio_speech', True)) }}

{{
    fivetran_utils.union_connections(
        connection_dictionary='openai_sources',
        single_source_name='openai',
        single_table_name='audio_speech'
    )
}}
