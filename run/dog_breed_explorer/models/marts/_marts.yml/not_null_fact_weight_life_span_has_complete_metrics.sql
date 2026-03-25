
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select has_complete_metrics
from `dog-breed-explorer-am`.`gold`.`fact_weight_life_span`
where has_complete_metrics is null



  
  
      
    ) dbt_internal_test