{% macro openai_usage_products() %}
    {{ return(adapter.dispatch('openai_usage_products', 'openai')()) }}
{% endmacro %}

{#- input_tokens is already the total prompt size (cache_read_tokens is a subset of it, not
    additional), so completion's total below is input + output only — adding cache_read_tokens
    would double-count the cached portion. web_search_call's request_col is num_requests (tool
    calls) rather than num_model_requests (underlying model invocations) — matches
    file_search_call's own convention, since both are tool calls that may not map 1:1 to a
    model request. -#}
{% macro default__openai_usage_products() %}
    {% do return([
        {'var': 'openai_using_completion', 'table': 'completion', 'product': 'completion', 'quantity_expr': 'input_tokens + output_tokens', 'quantity_unit': 'tokens', 'request_col': 'num_model_requests'},
        {'var': 'openai_using_embedding', 'table': 'embedding', 'product': 'embedding', 'quantity_expr': 'input_tokens', 'quantity_unit': 'tokens', 'request_col': 'num_model_requests'},
        {'var': 'openai_using_audio_transcription', 'table': 'audio_transcription', 'product': 'audio_transcription', 'quantity_expr': 'audio_seconds', 'quantity_unit': 'seconds', 'request_col': 'num_model_requests'},
        {'var': 'openai_using_audio_speech', 'table': 'audio_speech', 'product': 'audio_speech', 'quantity_expr': 'characters', 'quantity_unit': 'characters', 'request_col': 'num_model_requests'},
        {'var': 'openai_using_image', 'table': 'image', 'product': 'image', 'quantity_expr': none, 'quantity_unit': none, 'request_col': 'num_model_requests'},
        {'var': 'openai_using_moderation', 'table': 'moderation', 'product': 'moderation', 'quantity_expr': 'input_tokens', 'quantity_unit': 'tokens', 'request_col': 'num_model_requests'},
        {'var': 'openai_using_web_search_call', 'table': 'web_search_call', 'product': 'web_search', 'quantity_expr': none, 'quantity_unit': none, 'request_col': 'num_requests'},
        {'var': 'openai_using_file_search_call', 'table': 'file_search_call', 'product': 'file_search', 'quantity_expr': none, 'quantity_unit': none, 'request_col': 'num_requests', 'no_model': true},
    ]) %}
{% endmacro %}

{% macro openai_enabled_usage_products() %}
    {{ return(adapter.dispatch('openai_enabled_usage_products', 'openai')()) }}
{% endmacro %}

{#- The subset of openai_usage_products() whose guard var is currently enabled. Single
    source of truth for int_openai__enterprise_usage_unioned's union branches, and for
    `| length == 0` checks anywhere a model needs to know whether any product is on at all. -#}
{% macro default__openai_enabled_usage_products() %}
    {% set enabled_products = [] %}
    {% for product_config in openai.openai_usage_products() %}
        {% if var(product_config.var, True) %}{% do enabled_products.append(product_config) %}{% endif %}
    {% endfor %}
    {% do return(enabled_products) %}
{% endmacro %}
