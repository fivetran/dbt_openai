# dbt_openai v0.1.0

## Initial Release

This is the initial release of this package.

# 📣 What does this dbt package do?
- Transforms data from Fivetran's [OpenAI Platform/Enterprise connector](https://fivetran.com/docs/connectors/applications/openai) into analytics-ready tables covering spend, usage, and Codex Enterprise productivity across your organization.
- Materializes five end models:
  - [openai__cost_usage_report](https://github.com/fivetran/dbt_openai/blob/main/models/openai__cost_usage_report.sql): Daily OpenAI Platform spend and token usage by project and model. Cost is inferred via an implied per-token rate card whenever the Costs API doesn't already report a project directly.
  - [openai__enterprise_user_report](https://github.com/fivetran/dbt_openai/blob/main/models/openai__enterprise_user_report.sql): Daily OpenAI Platform activity by user, project, model, and product (completions, embeddings, audio transcription, audio speech, image generation, moderation, web search, and file search).
  - [openai__code_report](https://github.com/fivetran/dbt_openai/blob/main/models/openai__code_report.sql): Daily Codex Enterprise productivity (lines of code added/removed, threads, turns) plus credit and token consumption, by user.
  - [openai__user_summary](https://github.com/fivetran/dbt_openai/blob/main/models/openai__user_summary.sql): One row per user, with organization role, project membership, project-level custom roles, and all-time/month-to-date usage totals.
  - [openai__compliance_cost_report](https://github.com/fivetran/dbt_openai/blob/main/models/openai__compliance_cost_report.sql): Daily ChatGPT Enterprise (Compliance Platform) spend by user, product, surface, model, and SKU.
- Supports unioning multiple OpenAI Platform/Enterprise connections into a single set of models.
- Lets you disable any of the 19 optional source tables independently through `openai__using_<table>` variables, so the package still produces useful output from a partial sync.
- Supports passthrough metrics for bringing in custom cost, completion, Codex usage, and Compliance Platform cost fields unique to your account.
- Generates a comprehensive data dictionary of your source and modeled OpenAI data through the [dbt docs site](https://fivetran.github.io/dbt_openai/#!/overview).

For more information, refer to the [README](https://github.com/fivetran/dbt_openai/blob/main/README.md).
