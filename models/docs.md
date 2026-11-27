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

{% docs src_input_tokens %}
Number of input tokens metered for this usage record, including cached tokens.
{% enddocs %}

{% docs input_tokens %}
Number of input tokens metered for this usage record, excluding cached tokens (which are counted separately under `cache_read_tokens`).
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

{% docs compliance_product %}
The ChatGPT Enterprise product this spend belongs to (for example, `chatgpt`, `codex`, `work`, `hermes`, `chatgpt_agent`, `site_hosting`). Lowercased, because OpenAI sent some events from 2026-11-02 with lowercase names while others kept the original casing (`ChatGPT`, `Work`). OpenAI adds products without notice, so filter on the products you need rather than on a fixed list. `codex` and `work` cover the same activity as `openai__code_report`.
{% enddocs %}

{% docs compliance_sku %}
The billed SKU, as OpenAI names it. The format changed twice, so the same SKU can appear under different names over time:
- Before 2026-10-10: `GPT-5.6 Sol - Cached Input`
- From 2026-10-10: `GPT-6 Sol | processing standard | context standard | regional standard | gen mode single, text input cached`
- From 2026-11-02, for some SKUs: `app.gpt_6_sol.processing_standard....text_input_cached.v1`

To group by token type, match phrases all three formats share (reading underscores as spaces): `cache write`, `cached input` or `input cached`, `output`, and `input`, checked in that order.
{% enddocs %}

{% docs compliance_cost_unit %}
The unit this line item's cost is billed in, lowercased: `credits` before 2026-10-10 and `usd` from then on. Cost lands in `credits` or `cost_usd` to match.
{% enddocs %}

{% docs compliance_credits %}
Cost in ChatGPT Enterprise credits, for line items billed in credits (`cost_unit = 'credits'`, before 2026-10-10). Null on line items billed in USD. Can be negative on rollback events. Never add it to `cost_usd` directly; price it with your credit rate first, or use `total_cost_usd`.
{% enddocs %}

{% docs compliance_cost_usd %}
Cost in USD, for line items billed in USD (`cost_unit = 'usd'`, from 2026-10-10). Null on line items billed in credits. Can be negative on rollback events, which net out the events they reverse.
{% enddocs %}

{% docs compliance_estimated_cost_usd_amount %}
OpenAI's estimated USD equivalent of `credits`, provided by the source. Only populated on line items billed in credits; null from 2026-10-10. It reflects OpenAI's list price, which can differ from your contracted credit rate.
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
{% docs fivetran_deleted %}
Boolean indicating whether the record was soft-deleted by Fivetran.
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
