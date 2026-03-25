
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  -- No dog breed should weigh more than 120kg or less than 0.5kg.
-- Catches data corruption or parsing errors in the weight columns.
select
    breed_id,
    breed_name,
    avg_weight_kg
from `dog-breed-explorer-am`.`gold`.`fact_weight_life_span`
where avg_weight_kg < 0.5 or avg_weight_kg > 120
  
  
      
    ) dbt_internal_test