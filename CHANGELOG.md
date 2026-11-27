# dbt_openai v0.3.0

[PR #7](https://github.com/fivetran/dbt_openai/pull/7) includes the following updates:

## Schema/Data Change
**7 total changes • 3 possible breaking changes**

| Data Model(s) | Change type | Old | New | Notes |
| ------------- | ----------- | --- | --- | ----- |
| `openai__compliance_cost_report`<br>`stg_openai__compliance_cost_billing`<br>(Breaking) | Field value change | `credits` held USD from 2026-10-10 | `credits` holds credits only | OpenAI switched the Compliance cost log from credits to USD on 2026-10-10. `credits` is now null on line items billed in USD. |
| `openai__compliance_cost_report`<br>`stg_openai__compliance_cost`<br>(Breaking) | Field value change | `product` in mixed case (for example `ChatGPT`, `chatgpt`) | `product` lowercased | OpenAI sent some events from 2026-11-02 with lowercase product names while others kept the original casing. Filters on `product` should use lowercase values. |
| `openai__code_report`<br>(Breaking) | Field value change | `credits` is 0 when the source reports none | `credits` is null when the source reports none | The Codex Analytics API stopped returning credits on 2026-10-10. `estimated_cost_amount` is also null on those rows. Codex cost from that date is in `openai__compliance_cost_report` (products `codex` and `work`). |
| `openai__compliance_cost_report`<br>`stg_openai__compliance_cost_billing` | New field |  | `cost_usd` | Cost of line items billed in USD (from 2026-10-10). Null on line items billed in credits. |
| `openai__compliance_cost_report` | New field |  | `total_cost_usd` | `cost_usd` plus `credits` priced at the new `openai__credit_rate` variable. Only present when that variable is set. |
| `openai__compliance_cost_report`<br>`stg_openai__compliance_cost_billing` | Field value change | `cost_unit` as sent (`CREDITS`, `USD`) | `cost_unit` lowercased (`credits`, `usd`) | `cost_unit` is also added to the uniqueness test on `openai__compliance_cost_report`, since both units appear on 2026-10-10. |
| `stg_openai__compliance_cost_billing` | Removed field | `costs_log_id` |  | The `compliance_costs_organization_log_billing` source table has no `costs_log_id` column, so this field was always null. |

## Feature Update
- Adds the `openai__credit_rate` variable (USD per credit), which prices credits in both `openai__compliance_cost_report` (`total_cost_usd`) and `openai__code_report` (`estimated_cost_amount`). It replaces `openai__code_report_credit_rate`, which is still read when `openai__credit_rate` isn't set. See the [README](https://github.com/fivetran/dbt_openai/blob/main/README.md#pricing-credits-in-usd).
- Documents the Compliance cost log changes in the DECISIONLOG, including why rollback events with negative cost are kept, and documents the three SKU name formats and how to parse the token type from them.

## Bug Fix
- Fixes `openai__compliance_cost_report` returning no rows. Billing lines were joined to their cost event on `costs_log_id`, which the billing source table doesn't have, so the join matched nothing. Billing now joins on the event alone.
- Fixes Compliance cost after 2026-10-10 being reported as credits. OpenAI now bills in USD, so cost is split into `credits` and `cost_usd` by `cost_unit`, and the two units are never summed together.
- Fixes `openai__code_report` showing 0 credits after 2026-10-10, when the Codex Analytics API stopped returning credits. These rows now show null.

## Under the Hood
- Adds an `accepted_values` test (warn severity) on `cost_unit` in `stg_openai__compliance_cost_billing`, so a new cost unit is flagged instead of dropped from both cost columns.
- Updates the Compliance seed data to match the connector schema and adds USD-era line items, mixed-case and new products, and a rollback and re-issue cycle. Adds Codex seed rows with no credits.
- Adds the `integrity_compliance_cost_report` validation test, which ties `openai__compliance_cost_report` totals to the billing source, and a `Credit Rate` test scenario.

# dbt_openai v0.2.0

[PR #6](https://github.com/fivetran/dbt_openai/pull/6) includes the following updates:

## Feature Update
- **Breaking change**: Raises the minimum dbt version to 1.10.0.
- Adds `dbt_utils.unique_combination_of_columns` tests to staging and end models. If a test fails, please [open an issue](https://github.com/fivetran/dbt_openai/issues/new/choose).

# dbt_openai v0.1.2

[PR #3](https://github.com/fivetran/dbt_openai/pull/3) includes the following updates:

## Schema/Data Change
**1 total change • 0 possible breaking changes**

| Data Model(s) | Change type | Old | New | Notes |
| ------------- | ----------- | --- | --- | ----- |
| `stg_openai__completion` | New field |  | `service_tier` | Rows without a reported tier default to `default`. Used to match tier-prefixed cost line items to completion usage. |

## Bug Fix
- Fixes cost line items with a service-tier prefix (for example `priority | gpt-4o, input`, `fast mode | gpt-4o, output`, and `evals | priority | gpt-4o, output`) in `openai__cost_usage_report`. The tier prefix stayed in `model`, so cost never matched completion usage. Cost appeared on rows with no token volume, and the matching usage appeared as `unmatched` with no cost. These line items now parse to the model name, so cost and usage land on the same row.
- Fixes `model`, `model_family`, and `model_variant` being null on `cost_type = 'other'` rows in `openai__cost_usage_report` when the line item names a model (for example `text-embedding-3-large`, `GPT-4o`, or `OpenAI o1`). Line items without a model, such as `Assistants API`, stay null.
- Fixes `input_tokens` in `openai__cost_usage_report` double counting cached tokens. `input_tokens` may decrease as it now excludes cached tokens, which appear only in `cache_read_tokens`.
- Allows for negative token values in `openai__cost_usage_report`, as OpenAI occasionally reports a negative completion row for adjustment.

## Under the Hood
- `service_tier` is carried as an internal join key through `stg_openai__completion`, `int_openai__completion_unpivoted`, `int_openai__cost_by_model_day`, and `int_openai__cost_rate_card` and aggregated away in `openai__cost_usage_report`, preserving the existing output grain and schema.

# dbt_openai v0.1.1

[PR #2](https://github.com/fivetran/dbt_openai/pull/2) introduces the following update:

## Under the Hood
- Ensures the package is backwards-compatible with the `union_data` macro, which is leveraged in Quickstart for the downstream [AI Reporting](https://github.com/fivetran/dbt_ai_reporting) rollup package.

# dbt_openai v0.1.0

## Initial Release

This is the initial release of this package.

# What does this dbt package do?
- Transforms data from Fivetran's [OpenAI Platform/Enterprise connector](https://fivetran.com/docs/connectors/applications/openai) into analytics-ready tables covering spend, usage, and Codex Enterprise productivity across your organization.
- Materializes five end models:

| Table | Description |
| :---- | :---- |
| [openai__cost_usage_report](https://fivetran.github.io/dbt_openai/#!/model/model.openai.openai__cost_usage_report) | Daily OpenAI Platform spend and token usage by project and model. Cost is inferred via an implied per-token rate card whenever the Costs API doesn't already report a project directly. <br><br>**Example Analytics Questions:**<br><ul><li>Which projects or models are driving the most spend day over day?</li><li>How does token usage compare across projects and models over time?</li><li>How much cost can't be attributed to a specific project or model?</li></ul> |
| [openai__enterprise_user_report](https://fivetran.github.io/dbt_openai/#!/model/model.openai.openai__enterprise_user_report) | Daily OpenAI Platform activity by user, project, model, and product (completions, embeddings, audio transcription, audio speech, image generation, moderation, web search, and file search). <br><br>**Example Analytics Questions:**<br><ul><li>Which users are the heaviest consumers of a given product or model?</li><li>How is usage distributed across products (completions, embeddings, image, etc.) day to day?</li><li>Which projects have the most active users?</li></ul> |
| [openai__code_report](https://fivetran.github.io/dbt_openai/#!/model/model.openai.openai__code_report) | Daily Codex Enterprise productivity (lines of code added/removed, threads, turns) plus credit and token consumption, by user. <br><br>**Example Analytics Questions:**<br><ul><li>Who are the most active Codex users by lines of code or threads per day?</li><li>How much credit and token volume is Codex consuming per person over time?</li><li>Is Codex usage trending up or down across the organization?</li></ul> |
| [openai__user_summary](https://fivetran.github.io/dbt_openai/#!/model/model.openai.openai__user_summary) | One row per user, with organization role, project membership, project-level custom roles, and all-time/month-to-date usage totals. <br><br>**Example Analytics Questions:**<br><ul><li>Which users belong to the most projects or hold the most custom roles?</li><li>Who has been most active this month versus all time?</li><li>Which users haven't been active recently?</li><li>Which users own the most API keys, or haven't accepted their invite yet?</li></ul> |
| [openai__compliance_cost_report](https://fivetran.github.io/dbt_openai/#!/model/model.openai.openai__compliance_cost_report) | Daily ChatGPT Enterprise (Compliance Platform) spend by user, product, surface, model, and SKU. <br><br>**Example Analytics Questions:**<br><ul><li>Which users or products are driving the most ChatGPT Enterprise spend?</li><li>How does spend break down by surface (web, desktop, API) or client?</li><li>Which SKUs or service tiers make up the bulk of Compliance Platform cost?</li></ul> |

- Supports unioning multiple OpenAI Platform/Enterprise connections into a single set of models.
- Lets you disable any of the 19 optional source tables through `openai__using_<table>` variables (a few cover more than one table each), so the package still produces useful output from a partial sync — see the README's [Disable models for non-existent sources](https://github.com/fivetran/dbt_openai/blob/main/README.md#disable-models-for-non-existent-sources) section.
- Supports passthrough metrics for bringing in custom cost, completion, Codex usage, and Compliance Platform cost fields unique to your account.
- Generates a comprehensive data dictionary of your source and modeled OpenAI data through the [dbt docs site](https://fivetran.github.io/dbt_openai/#!/overview).

For more information, refer to the [README](https://github.com/fivetran/dbt_openai/blob/main/README.md).
