<!--section="openai_transformation_model"-->
# OpenAI dbt Package

This dbt package transforms data from Fivetran's OpenAI Platform/Enterprise connector into analytics-ready tables.

## Resources

- Number of materialized models¹: 48
- Connector documentation
  - [OpenAI connector documentation](https://fivetran.com/docs/connectors/applications/openai)
- dbt package documentation
  - [GitHub repository](https://github.com/fivetran/dbt_openai)
  - [dbt Docs](https://fivetran.github.io/dbt_openai/#!/overview)
  - [DAG](https://fivetran.github.io/dbt_openai/#!/overview?g_v=1)
  - [Changelog](https://github.com/fivetran/dbt_openai/blob/main/CHANGELOG.md)
- dbt Core™ supported versions
  - `>=1.3.0, <3.0.0`

## What does this dbt package do?
This package enables you to analyze OpenAI Platform spend, usage, and Codex Enterprise productivity across your organization. It creates enriched models with metrics focused on daily cost by project and model, per-user activity across every OpenAI product, Codex Enterprise coding productivity, and per-user usage summaries.

> Note: No single source table in this connector's schema is used by the majority of active connections (the most common, `project`, is used by roughly 39% of them). Because of this, every one of the 20 source tables this package can use is gated behind its own `openai_using_<table>` variable (see [Enable/Disable models](#enabledisable-models) below) — this package guards far more tables than most Fivetran dbt packages do, and that's intentional rather than a placeholder.

### Output schema
Final output tables are generated in the following target schema:

```
<your_database>.<connector/schema_name>_openai_reports
```

### Final output tables

By default, this package materializes the following final tables:

| Table | Description |
| :---- | :---- |
| [openai__cost_usage_report](https://fivetran.github.io/dbt_openai/#!/model/model.openai.openai__cost_usage_report) | Daily OpenAI Platform spend and token usage by project and model. One row per source relation, day, project, and model, plus one org-level row per source relation/day for cost that can't be attributed to a project (`cost_type = 'other'`, e.g. aggregate feature charges like "Assistants API", or token-type cost with no matching completion volume). Cost is inferred by applying an implied per-token rate (Costs endpoint spend ÷ completion token volume) to each project's token share, since the Costs endpoint doesn't report a project breakdown directly. Still useful with only `openai_using_cost` or only `openai_using_completion` enabled — see [Additional configurations](#optional-additional-configurations). <br><br>**Example Analytics Questions:**<br><ul><li>Which projects or models are driving the most spend day over day?</li><li>How does token usage compare across projects and models over time?</li><li>How much cost can't be attributed to a specific project or model?</li></ul> |
| [openai__enterprise_user_report](https://fivetran.github.io/dbt_openai/#!/model/model.openai.openai__enterprise_user_report) | Daily OpenAI Platform activity by user, project, model, and product (completions, embeddings, audio transcription, audio speech, image generation, moderation, web search, and file search). Cost is not available at this grain — the Costs endpoint doesn't report per-user attribution. <br><br>**Example Analytics Questions:**<br><ul><li>Which users are the heaviest consumers of a given product or model?</li><li>How is usage distributed across products (completions, embeddings, image, etc.) day to day?</li><li>Which projects have the most active users?</li></ul> |
| [openai__code_report](https://fivetran.github.io/dbt_openai/#!/model/model.openai.openai__code_report) | Daily Codex Enterprise productivity (lines of code added/removed, threads, turns) plus credit and token consumption, one row per source relation, day, and user. Per-model and per-speed detail is rolled up onto this grain rather than fanned out into separate rows. <br><br>**Example Analytics Questions:**<br><ul><li>Who are the most active Codex users by lines of code or threads per day?</li><li>How much credit and token volume is Codex consuming per person over time?</li><li>Is Codex usage trending up or down across the organization?</li></ul> |
| [openai__user_summary](https://fivetran.github.io/dbt_openai/#!/model/model.openai.openai__user_summary) | One row per source relation and user, with organization role, project membership, project-level custom roles, and all-time/month-to-date usage totals. <br><br>**Example Analytics Questions:**<br><ul><li>Which users belong to the most projects or hold the most custom roles?</li><li>Who has been most active this month versus all time?</li><li>Which users haven't been active recently?</li></ul> |

¹ Each Quickstart transformation job run materializes these models if all components of this data model are enabled. This count includes all staging, intermediate, and final models materialized as `view`, `table`, or `ephemeral`.

---

## Prerequisites
To use this dbt package, you must have the following:

- At least one Fivetran OpenAI Platform/Enterprise connection syncing data into your destination.
- A **BigQuery**, **Snowflake**, **Redshift**, **Databricks**, or **PostgreSQL** destination.

## How do I use the dbt package?
You can either add this dbt package in the Fivetran dashboard or import it into your dbt project:

- To add the package in the Fivetran dashboard, follow our [Quickstart guide](https://fivetran.com/docs/transformations/data-models/quickstart-management).
- To add the package to your dbt project, follow the setup instructions below.

<!--section-end-->

### Install the package
Include the following openai package version in your `packages.yml` file:
> TIP: Check [dbt Hub](https://hub.getdbt.com/) for the latest installation instructions or [read the dbt docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.
```yml
packages:
  - package: fivetran/openai
    version: [">=0.1.0", "<0.2.0"]
```

### Define database and schema variables
#### Option A: Single connection
By default, this package runs using your destination and the `openai` schema. If this is not where your OpenAI data is (for example, if your OpenAI schema is named `openai_fivetran`), add the following configuration to your root `dbt_project.yml` file:

```yml
vars:
    openai_database: your_destination_name
    openai_schema: your_schema_name
```

#### Option B: Union multiple connections
If you have multiple OpenAI connections in Fivetran and would like to use this package on all of them simultaneously, we have provided functionality to do so. For each source table, the package will union all of the data together and pass the unioned table into the transformations. The `source_relation` column in each model indicates the origin of each record.

To use this functionality, you will need to set the `openai_sources` variable in your root `dbt_project.yml` file:

```yml
# dbt_project.yml

vars:
  openai:
    openai_sources:
      - database: connection_1_destination_name # Required
        schema: connection_1_schema_name # Required
        name: connection_1_source_name # Required only if following the step in the following subsection

      - database: connection_2_destination_name
        schema: connection_2_schema_name
        name: connection_2_source_name
```

#### Recommended: Incorporate unioned sources into DAG
If you use [Fivetran Transformations for dbt Core™](https://fivetran.com/docs/transformations/dbt#transformationsfordbtcore) and are unioning multiple OpenAI connections, you can define your sources in a property `.yml` file, [using this as a template](https://github.com/fivetran/dbt_openai/blob/main/models/staging/src_openai.yml). Set the variable `has_defined_sources: true` under the OpenAI namespace in your `dbt_project.yml`. Otherwise, your OpenAI connections won't appear in your DAG. See the `union_connections` macro [documentation](https://github.com/fivetran/dbt_fivetran_utils/tree/releases/v0.4.latest#optional-union-connections-defined-sources-configuration) for full configuration details.

### Enable/Disable models

> _This step is optional if you are unioning multiple connections together in the previous step. The `union_data` macro will create empty staging models for sources that are not found in any of your OpenAI schemas/databases. However, you can still leverage the below variables if you would like to avoid this behavior._

This package takes into consideration that not every OpenAI Platform/Enterprise account syncs every source table, and allows you to disable the corresponding functionality for any of them: `cost`, `completion`, `embedding`, `audio_transcription`, `audio_speech`, `image`, `moderation`, `web_search_call`, `file_search_call`, `codex_usage`, `codex_usage_model`, `project`, `project_api_key`, `project_user`, `project_user_role`, `project_role`, `users_role`, `groups`, and `invite`. `users` isn't included here — it's the spine of `openai__user_summary` with no partial-value alternative, so `stg_openai__users` and `openai__user_summary` always build.

By default, all of these variables are assumed to be `true`. Add variables for only the tables you want to disable:

```yml
vars:
    openai_using_cost:                   False   # Disable if you are not syncing the cost table
    openai_using_completion:             False   # Disable if you are not syncing the completion table
    openai_using_embedding:              False   # Disable if you are not syncing the embedding table
    openai_using_audio_transcription:    False   # Disable if you are not syncing the audio_transcription table
    openai_using_audio_speech:           False   # Disable if you are not syncing the audio_speech table
    openai_using_image:                  False   # Disable if you are not syncing the image table
    openai_using_moderation:             False   # Disable if you are not syncing the moderation table
    openai_using_web_search_call:        False   # Disable if you are not syncing the web_search_call table
    openai_using_file_search_call:       False   # Disable if you are not syncing the file_search_call table
    openai_using_codex_usage:            False   # Disable if you are not syncing the codex_usage table
    openai_using_codex_usage_model:      False   # Disable if you are not syncing the codex_usage_model table
    openai_using_project:                False   # Disable if you are not syncing the project table
    openai_using_project_api_key:        False   # Disable if you are not syncing the project_api_key table
    openai_using_project_user:           False   # Disable if you are not syncing the project_user table
    openai_using_project_user_role:      False   # Disable if you are not syncing the project_user_role table
    openai_using_project_role:           False   # Disable if you are not syncing the project_role table
    openai_using_users_role:             False   # Disable if you are not syncing the users_role table
    openai_using_groups:                 False   # Disable if you are not syncing the groups table
    openai_using_invite:                 False   # Disable if you are not syncing the invite table
```

### (Optional) Additional configurations
<details open><summary>Expand/Collapse details</summary>

#### Partial cost and code reporting
`openai__cost_usage_report` and `openai__code_report` are each built from two optional source-table pairs, and each model still produces useful (differently-shaped) output when only one side of its pair is enabled:

- `openai__cost_usage_report` uses `cost` and `completion`. With only `openai_using_cost` enabled, the model falls back to cost by day, project, model, and `cost_type` (no token columns, since only `completion` reports token counts). With only `openai_using_completion` enabled, the cost and currency columns drop entirely and only usage remains.
- `openai__code_report` uses `codex_usage` and `codex_usage_model`. `codex_usage` reports its own day-level credit/token totals, so those columns are present whenever either table is enabled — only `count_models_used` requires `openai_using_codex_usage_model` specifically. With `openai_using_codex_usage` disabled, `actor_email` and the productivity columns (lines of code, threads, turns) drop entirely, since only `codex_usage` resolves the email or reports that activity.

Disabling one table in a pair doesn't disable the whole model — it just drops the columns that table alone can supply. See the column descriptions in [models/openai.yml](https://github.com/fivetran/dbt_openai/blob/main/models/openai.yml) for the full breakdown of which columns depend on which variable.

#### Inferred cost attribution
The OpenAI Costs API doesn't report a project-level cost breakdown. To still provide per-project spend, `openai_cost` in `openai__cost_usage_report` is inferred: this package derives an implied per-token rate from the Costs endpoint's daily spend per model and unit type, then applies that rate to each project's share of that day's token volume (from `completion`). Cost that can't be tied back to a matching model/day of completion volume — or that isn't token-based to begin with (e.g. aggregate feature charges like "Assistants API") — lands in a `cost_type = 'other'` row so that `sum(openai_cost)` still ties out to the total in the source `cost` table.

#### Model family and variant
The cost and enterprise user reports retain the original `model` and add two parsed columns:

| model | model_family | model_variant |
| --- | --- | --- |
| `gpt-4o-mini-2024-07-18` | `gpt-4o` | `mini` |
| `gpt-5.2-codex` | `gpt-5.2` | `codex` |
| `gpt-6-astra` | `gpt-6` | `astra` |
| `o4-mini` | `o4` | `mini` |
| `o3-deep-research` | `o3` | `deep-research` |

Parsing trims and lowercases names, unwraps fine-tuned `ft:` names, and removes a trailing YYYY-MM-DD-shaped snapshot suffix. Numeric GPT and o-series families are structural, so future versions following those conventions work automatically. Known named prefixes such as `codex` and `text-embedding` also form families; their remaining suffix stays intact as the variant. Unrecognized names retain the original `model` as the family and have a null variant. Names without a variant also have a null variant. These fields describe names, not architecture, capabilities, or billing rates.

#### Model family overrides

To override an exact base-model name, including any dated suffix:

```yml
vars:
  openai_model_family_overrides:
    gpt-4o-mini: gpt-4o-mini
    codex-mini-latest: codex-mini
```

Keys are trimmed and lowercased, and match after removing the `ft:` wrapper. Overrides take precedence over built-in family rules and do not change the structurally parsed variant. Use the `openai_model_family` macro for family SQL and `openai_model_variant` for variant SQL. Warehouse syntax is selected with Jinja.

#### Change the source table references
If an individual source table has a different name than the package expects, add the table name as it appears in your destination to the respective variable:

> IMPORTANT: See this project's [`dbt_project.yml`](https://github.com/fivetran/dbt_openai/blob/main/dbt_project.yml) variable declarations to see the expected names.

```yml
vars:
    openai_<default_source_table_name>_identifier: your_table_name
```

#### Changing the Build Schema
By default this package will build the OpenAI staging and intermediate models within a schema titled (`<target_schema>` + `_openai_staging`), and the OpenAI final models within a schema titled (`<target_schema>` + `_openai_reports`) in your target database. If this is not where you would like your modeled OpenAI data to be written to, add the following configuration to your root `dbt_project.yml` file:

```yml
models:
    openai:
      +schema: my_new_schema_name # Leave +schema: blank to use the default target_schema.
      staging:
        +schema: my_new_schema_name # Leave +schema: blank to use the default target_schema.
```

#### Passthrough metrics
This package includes all source columns defined in the macros folder by default. However, if you have data unique to your OpenAI account that isn't already included in the staging models, you can bring it in with a passthrough metric variable:

```yml
vars:
    openai__cost_passthrough_metrics: []
    openai__completion_passthrough_metrics: []
    openai__codex_usage_passthrough_metrics: []
    openai__codex_usage_model_passthrough_metrics: []
    openai__compliance_cost_passthrough_metrics: []
    openai__compliance_cost_billing_passthrough_metrics: []
```

These variables allow you to bring in additional columns from `stg_openai__cost`, `stg_openai__completion`, `stg_openai__codex_usage`, `stg_openai__codex_usage_model`, `stg_openai__compliance_cost`, and `stg_openai__compliance_cost_billing`, respectively. Each field is summed at every point between its source table and the report(s) it feeds (a no-op when the field already reaches its report at the source table's own grain, with nothing aggregating it further). They all accept the same format, supporting datatype casting, aliasing, and custom transformations:

```yml
vars:
  openai__completion_passthrough_metrics:
    - name: "field_id"
      alias: "field_name"
      transform_sql: "cast(field_id as int64)"
    - name: "another_field_name"
```

`name` is required and is the column name as it appears in the raw source table. `alias` and `transform_sql` are optional — `alias` renames the output column, and `transform_sql` provides a custom SQL expression (referencing `name` or `alias`) instead of a plain passthrough.

#### Source casing for case-sensitive destinations
By default, the package applies case-insensitive comparisons when resolving `source_relation` values. If your destination is case-sensitive and you want downstream transformations to respect the exact casing of your source database and schema names, set the following variable:

```yml
vars:
    fivetran_using_source_casing: true
```

</details>

### (Optional) Orchestrate your models with Fivetran Transformations for dbt Core™
<details><summary>Expand for details</summary>
<br>

Fivetran offers the ability for you to orchestrate your dbt project through [Fivetran Transformations for dbt Core™](https://fivetran.com/docs/transformations/dbt#transformationsfordbtcore). Learn how to set up your project for orchestration through Fivetran in our [Transformations for dbt Core setup guides](https://fivetran.com/docs/transformations/dbt/setup-guide#transformationsfordbtcoresetupguide).
</details>

## Does this package have dependencies?
This dbt package is dependent on the following dbt packages. These dependencies are installed by default within this package. For more information on the following packages, refer to the [dbt hub](https://hub.getdbt.com/) site.
> IMPORTANT: If you have any of these dependent packages in your own `packages.yml` file, we highly recommend that you remove them from your root `packages.yml` to avoid package version conflicts.

```yml
packages:
    - package: fivetran/fivetran_utils
      version: [">=0.4.12", "<0.5.0"]

    - package: dbt-labs/dbt_utils
      version: [">=1.0.0", "<2.0.0"]
```

<!--section="openai_maintenance"-->
## How is this package maintained and can I contribute?

### Package Maintenance
The Fivetran team maintaining this package only maintains the [latest version](https://hub.getdbt.com/fivetran/openai/latest/) of the package. We highly recommend you stay consistent with the latest version of the package and refer to the [CHANGELOG](https://github.com/fivetran/dbt_openai/blob/main/CHANGELOG.md) and release notes for more information on changes across versions.

### Contributions
A small team of analytics engineers at Fivetran develops these dbt packages. However, the packages are made better by community contributions.

We highly encourage and welcome contributions to this package. Learn how to contribute to a package in dbt's [Contributing to an external dbt package article](https://discourse.getdbt.com/t/contributing-to-a-dbt-package/657).

### Opinionated Modelling Decisions
This dbt package takes an opinionated stance on a few points worth knowing before you build on top of it:

- `openai_cost` in `openai__cost_usage_report` is used directly from the Costs API when it already reports a project, and inferred via an implied per-token rate card otherwise — see [Inferred cost attribution](#inferred-cost-attribution) above for the mechanism.
- This package is designed to eventually roll up alongside a Claude/Anthropic usage package into a shared multi-vendor AI reporting package. Column names such as `source_relation`, `date_day`, `actor_user_id`, `actor_email`, `openai_cost`, `currency`, and `cost_type` were deliberately aligned with the equivalent columns in Fivetran's Claude/Anthropic dbt package where the underlying concepts match.

<!--section-end-->

## Are there any resources available?
- If you have questions or want to reach out for help, see the [GitHub Issue](https://github.com/fivetran/dbt_openai/issues/new/choose) section to find the right avenue of support for you.
- If you would like to provide feedback to the dbt package team at Fivetran or would like to request a new dbt package, fill out our [Feedback Form](https://www.surveymonkey.com/r/DQ7K7WW).
