
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select l_orderkey
from "iceberg"."tpch"."lineitem"
where l_orderkey is null



  
  
      
    ) dbt_internal_test