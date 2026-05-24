
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select o_orderkey
from "iceberg"."tpch"."orders"
where o_orderkey is null



  
  
      
    ) dbt_internal_test