
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select breed_name
from `dog-breed-explorer-am`.`silver`.`stg_dog_breeds`
where breed_name is null



  
  
      
    ) dbt_internal_test