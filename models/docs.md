{% docs project_id %}
Unique identifier for the OpenAI Platform project.
{% enddocs %}

{% docs user_id %}
Unique identifier for the OpenAI Platform user.
{% enddocs %}

{% docs api_key_id %}
Unique identifier for the project-scoped API key used to make this request.
{% enddocs %}

{% docs model %}
Name of the OpenAI model used for this request (e.g. `gpt-4o`, `text-embedding-3-small`).
{% enddocs %}

{% docs usage_started_at %}
Timestamp marking the start of the usage or cost reporting bucket this record covers.
{% enddocs %}

{% docs usage_ended_at %}
Timestamp marking the end of the usage or cost reporting bucket this record covers.
{% enddocs %}

{% docs api_object_type %}
The API object type for this record, as reported by OpenAI (for example, `organization.usage.completions.result`).
{% enddocs %}

{% docs organization_id %}
Unique identifier for the OpenAI organization.
{% enddocs %}

{% docs input_tokens %}
Number of input tokens metered for this usage record.
{% enddocs %}

{% docs cache_read_tokens %}
Number of input tokens served from cache (billed at a reduced rate) for this usage record.
{% enddocs %}

{% docs output_tokens %}
Number of output tokens metered for this usage record.
{% enddocs %}

{% docs num_model_requests %}
Number of API requests to the underlying model represented by this usage record.
{% enddocs %}

{% docs num_requests %}
Number of tool calls represented by this usage record.
{% enddocs %}

{% docs credits %}
Codex credits consumed, the billing unit for Codex Enterprise usage (not USD).
{% enddocs %}

{% docs cost_amount %}
Cost of this line item, as reported by the OpenAI Costs API, in the unit given by `currency_code`.
{% enddocs %}

{% docs openai_cost %}
Cost attributed to this row, in the unit given by `currency`. Used directly from `cost_amount`
when the Costs API already reports a project_id; otherwise inferred by applying an implied
per-token rate card. See `cost_attribution_method`.
{% enddocs %}

{% docs fivetran_synced %}
Timestamp of the most recent Fivetran sync for this record.
{% enddocs %}

{% docs date_day %}
Day the cost and usage apply to.
{% enddocs %}

{% docs model_family %}
Structural reporting family parsed from the model name, preserving version lines such as `gpt-4o`, `gpt-5.2`, and `o4`. Fine-tuned `ft:` names use their base model. `openai_model_family_overrides` takes precedence for exact base-model names. Unrecognized names return the original model value.
{% enddocs %}

{% docs model_variant %}
The model-name suffix remaining after its family and any dated snapshot suffix are removed — for example, `gpt-4o-mini-2024-07-18` yields `mini`. Null when no suffix remains or the name is unrecognized.
{% enddocs %}

{% docs project_name %}
Display name of the OpenAI Platform project.
{% enddocs %}

{% docs email %}
Email address of the person behind this activity.
{% enddocs %}

{% docs actor_email %}
Email address of the person behind this activity, lowercased. Used as the durable person key across the enterprise and Codex reports, since it survives key rotations and offboarding in a way an internal ID does not.
{% enddocs %}

{% docs actor_user_id %}
Identifier of the OpenAI Platform user this activity or summary belongs to. Joins to `stg_openai__users.user_id`.
{% enddocs %}

{% docs source_relation %}
The record's source if the unioning functionality is used. Otherwise this field will be empty.
{% enddocs %}
