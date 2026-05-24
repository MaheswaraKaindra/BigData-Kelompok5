
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select order_priority
from "iceberg"."tpch_mart_mart"."mart_revenue_summary"
where order_priority is null



  
  
      
    ) dbt_internal_test