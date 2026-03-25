
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select avg_life_span_years
from (select * from `dog-breed-explorer-am`.`gold`.`fact_weight_life_span` where life_span_min is not null) dbt_subquery
where avg_life_span_years is null



  
  
      
    ) dbt_internal_test