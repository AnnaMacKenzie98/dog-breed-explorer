
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select breed_id
from `dog-breed-explorer-am`.`gold`.`fact_weight_life_span`
where breed_id is null



  
  
      
    ) dbt_internal_test