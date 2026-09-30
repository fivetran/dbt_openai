{{ config(enabled=var('openai__using_cost', True) and var('openai__using_completion', True)) }}

-- Only token cost not already attributed to a project needs a rate card; "other" (non-token) rows have no model/token_unit_type to key a rate on.
with token_cost_by_model_day as (

    select *
    from {{ ref('int_openai__cost_by_model_day') }}
    where cost_type = 'tokens'

),

unattributed_cost as (

    select *
    from token_cost_by_model_day
    where project_id is null

),

-- Projects already billed directly for this day/model/unit; their token volume is excluded from the rate denominator below since it's already paid for.
directly_attributed_projects as (

    select distinct
        source_relation,
        date_day,
        model,
        token_unit_type,
        project_id
    from token_cost_by_model_day
    where project_id is not null

),

completion_unpivoted as (

    select *
    from {{ ref('int_openai__completion_unpivoted') }}

),

-- The rate denominator: token volume from projects with no direct cost that day. Left joined, not inner, so an unmatched cost slice gets rate_per_token = null instead of being dropped.
unattributed_token_totals as (

    select
        completion_unpivoted.source_relation,
        completion_unpivoted.date_day,
        completion_unpivoted.model,
        completion_unpivoted.token_unit_type,
        sum(completion_unpivoted.token_quantity) as token_quantity
    from completion_unpivoted
    left join directly_attributed_projects
        on directly_attributed_projects.source_relation = completion_unpivoted.source_relation
        and directly_attributed_projects.date_day = completion_unpivoted.date_day
        and directly_attributed_projects.model = completion_unpivoted.model
        and directly_attributed_projects.token_unit_type = completion_unpivoted.token_unit_type
        and directly_attributed_projects.project_id = completion_unpivoted.project_id
    where directly_attributed_projects.project_id is null
    {{ dbt_utils.group_by(n=4) }}

),

final as (

    select
        unattributed_cost.source_relation,
        unattributed_cost.date_day,
        unattributed_cost.model,
        unattributed_cost.token_unit_type,
        unattributed_cost.cost_amount,
        unattributed_cost.currency_code,
        unattributed_token_totals.token_quantity as total_token_quantity,
        {{ dbt_utils.safe_divide('unattributed_cost.cost_amount', 'unattributed_token_totals.token_quantity') }} as rate_per_token
    from unattributed_cost
    left join unattributed_token_totals
        on unattributed_token_totals.source_relation = unattributed_cost.source_relation
        and unattributed_token_totals.date_day = unattributed_cost.date_day
        and unattributed_token_totals.model = unattributed_cost.model
        and unattributed_token_totals.token_unit_type = unattributed_cost.token_unit_type

)

select *
from final
