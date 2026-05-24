{{ config(materialized='view') }}

-- Union yearly aggregates to keep each batch small and memory friendly
with yearly as (
    select * from {{ ref('mart_revenue_summary_y1992') }}
    union all
    select * from {{ ref('mart_revenue_summary_y1993') }}
    union all
    select * from {{ ref('mart_revenue_summary_y1994') }}
    union all
    select * from {{ ref('mart_revenue_summary_y1995') }}
    union all
    select * from {{ ref('mart_revenue_summary_y1996') }}
    union all
    select * from {{ ref('mart_revenue_summary_y1997') }}
    union all
    select * from {{ ref('mart_revenue_summary_y1998') }}
)

select
    order_priority,
    line_status,
    sum(total_orders) as total_orders,
    sum(total_net_revenue) as total_net_revenue
from yearly
group by 1, 2
order by total_net_revenue desc