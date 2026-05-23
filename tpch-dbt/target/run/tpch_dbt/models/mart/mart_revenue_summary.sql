
  
    

    create table "iceberg"."tpch_mart_mart"."mart_revenue_summary__dbt_tmp"
      
      
    as (
      with orders as (
    select * from "iceberg"."tpch_mart_staging"."stg_orders"
),

lineitem as (
    select * from "iceberg"."tpch_mart_staging"."stg_lineitem"
)

select 
    o.order_priority,
    lineitem.line_status,
    count(distinct o.order_id) as total_orders,

    -- jinja macro to calculate discounted price
    sum(
    lineitem.extended_price * (1 - lineitem.discount)
) as total_net_revenue

from lineitem
join orders o on lineitem.order_id = o.order_id
group by 1, 2
order by total_net_revenue desc
    );

  