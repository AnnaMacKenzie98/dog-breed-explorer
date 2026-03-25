
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  -- Ensures the pipeline loaded a reasonable number of breeds.
-- The Dog API returns ~170 breeds; fewer than 100 indicates a data issue.
select count(*) as row_count
from `dog-breed-explorer-am`.`silver`.`stg_dog_breeds`
having count(*) < 100
  
  
      
    ) dbt_internal_test