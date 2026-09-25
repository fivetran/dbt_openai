{% macro openai_enabled_usage_products() %}
    {{ return(adapter.dispatch('openai_enabled_usage_products', 'openai')()) }}
{% endmacro %}

{#- Product catalog filtered to enabled guard vars. completion sums input+output (cache_read is already in input); web_search/file_search use num_requests, not num_model_requests. -#}
{% macro default__openai_enabled_usage_products() %}
    {% set all_products = [
        {'var': 'openai__using_completion', 'table': 'completion', 'product': 'completion', 'quantity_expr': 'input_tokens + output_tokens', 'quantity_unit': 'tokens', 'request_col': 'num_model_requests'},
        {'var': 'openai__using_embedding', 'table': 'embedding', 'product': 'embedding', 'quantity_expr': 'input_tokens', 'quantity_unit': 'tokens', 'request_col': 'num_model_requests'},
        {'var': 'openai__using_audio_transcription', 'table': 'audio_transcription', 'product': 'audio_transcription', 'quantity_expr': 'audio_seconds', 'quantity_unit': 'seconds', 'request_col': 'num_model_requests'},
        {'var': 'openai__using_audio_speech', 'table': 'audio_speech', 'product': 'audio_speech', 'quantity_expr': 'characters', 'quantity_unit': 'characters', 'request_col': 'num_model_requests'},
        {'var': 'openai__using_image', 'table': 'image', 'product': 'image', 'quantity_expr': none, 'quantity_unit': none, 'request_col': 'num_model_requests'},
        {'var': 'openai__using_moderation', 'table': 'moderation', 'product': 'moderation', 'quantity_expr': 'input_tokens', 'quantity_unit': 'tokens', 'request_col': 'num_model_requests'},
        {'var': 'openai__using_web_search_call', 'table': 'web_search_call', 'product': 'web_search', 'quantity_expr': none, 'quantity_unit': none, 'request_col': 'num_requests'},
        {'var': 'openai__using_file_search_call', 'table': 'file_search_call', 'product': 'file_search', 'quantity_expr': none, 'quantity_unit': none, 'request_col': 'num_requests', 'no_model': true},
    ] %}
    {% set enabled_products = [] %}
    {% for product_config in all_products %}
        {% if var(product_config.var, True) %}{% do enabled_products.append(product_config) %}{% endif %}
    {% endfor %}
    {% do return(enabled_products) %}
{% endmacro %}
