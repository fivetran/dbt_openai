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
Structural reporting family derived from the model name, preserving version lines such as `gpt-4o`, `gpt-5.2`, and `o4`. Names are trimmed and lowercased for parsing; fine-tuned `ft:` names use their base model. Numeric GPT versions allow an optional decimal version and single-letter suffix; o-series versions contain `o` followed by digits. Known named product prefixes include `codex`, `gpt-image`, and `text-embedding`. Exact normalized base-model overrides in `openai_model_family_overrides` take precedence, including any snapshot suffix in the key. Unrecognized names return the original model value; null remains null. These labels are reporting categories, not architecture or pricing rules.
{% enddocs %}

{% docs model_variant %}
The remaining normalized model-name suffix after its structurally recognized family and a trailing YYYY-MM-DD-shaped snapshot suffix are removed. For example, `gpt-4o-mini-2024-07-18` yields `mini`, `gpt-5.2-codex` yields `codex`, and `o3-deep-research` yields `deep-research`. Compound suffixes stay intact; no size or capability is inferred. Named product families follow the same rule, so `text-embedding-3-large` yields `3-large`. Null when no suffix remains or the name structure is unrecognized. Fine-tuned names use their base model. Family overrides do not change variant parsing. The original `model` value is preserved in reports.
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
