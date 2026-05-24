
  
    

    create table "iceberg"."tpch_mart_mart"."mart_revenue_summary_y1998__dbt_tmp"
      
      
    as (
      with orders as (
    -- One-year slice for 1998 to keep each batch lightweight
    select *
    from "iceberg"."tpch_mart_staging"."stg_orders"
    where order_date >= date '1998-01-01'
      and order_date <  date '1999-01-01'
),

lineitem_agg as (
    -- Pre-aggregate lineitem per order to reduce join size and memory usage
    select
        order_id,
        line_status,
        sum(
    extended_price * (1 - discount)
) as net_revenue
    from "iceberg"."tpch_mart_staging"."stg_lineitem"
    where ship_date >= date '1998-01-01'
      and ship_date <  date '1999-01-01'
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
    );

  