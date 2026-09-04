{% macro openai_usage_products() %}
    {% do return([
        {'var': 'openai_using_completion', 'table': 'completion', 'product': 'completion', 'token_expr': 'input_tokens + cache_read_tokens + output_tokens', 'request_col': 'num_model_requests'},
        {'var': 'openai_using_embedding', 'table': 'embedding', 'product': 'embedding', 'token_expr': 'input_tokens', 'request_col': 'num_model_requests'},
        {'var': 'openai_using_audio_transcription', 'table': 'audio_transcription', 'product': 'audio_transcription', 'token_expr': none, 'request_col': 'num_model_requests'},
        {'var': 'openai_using_audio_speech', 'table': 'audio_speech', 'product': 'audio_speech', 'token_expr': 'input_tokens', 'request_col': 'num_model_requests'},
        {'var': 'openai_using_image', 'table': 'image', 'product': 'image', 'token_expr': none, 'request_col': 'num_model_requests'},
        {'var': 'openai_using_moderation', 'table': 'moderation', 'product': 'moderation', 'token_expr': 'input_tokens', 'request_col': 'num_model_requests'},
        {'var': 'openai_using_web_search_call', 'table': 'web_search_call', 'product': 'web_search', 'token_expr': none, 'request_col': 'num_model_requests'},
        {'var': 'openai_using_file_search_call', 'table': 'file_search_call', 'product': 'file_search', 'token_expr': none, 'request_col': 'num_requests', 'no_model': true},
    ]) %}
{% endmacro %}

{#- The subset of openai_usage_products() whose guard var is currently enabled. Single
    source of truth for int_openai__enterprise_usage_unioned's union branches, and for
    `| length == 0` checks anywhere a model needs to know whether any product is on at all. -#}
{% macro openai_enabled_usage_products() %}
    {% set enabled_products = [] %}
    {% for product_config in openai_usage_products() %}
        {% if var(product_config.var, True) %}{% do enabled_products.append(product_config) %}{% endif %}
    {% endfor %}
    {% do return(enabled_products) %}
{% endmacro %}
