
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select line_status
from "iceberg"."tpch_mart_mart"."mart_revenue_summary"
where line_status is null



  
  
      
    ) dbt_internal_test