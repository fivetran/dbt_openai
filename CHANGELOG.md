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
