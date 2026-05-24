with orders as (
    -- One-year slice for 1997 to keep each batch lightweight
    select *
    from {{ ref('stg_orders') }}
    where order_date >= date '1997-01-01'
      and order_date <  date '1998-01-01'
),

lineitem_agg as (
    -- Pre-aggregate lineitem per order to reduce join size and memory usage
    select
        order_id,
        line_status,
        sum({{ calculate_discounted_price('extended_price', 'discount') }}) as net_revenue
    from {{ ref('stg_lineitem') }}
    where ship_date >= date '1997-01-01'
      and ship_date <  date '1998-01-01'
    group by 1, 2
)

select
    o.order_priority,
    l.line_status,
    count(*) as total_orders,
    sum(l.net_revenue) as total_net_revenue
from lineitem_agg l
join orders o on l.order_id = o.order_id
group by 1, 2
