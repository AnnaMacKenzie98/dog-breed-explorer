
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select breed_name
from `dog-breed-explorer-am`.`gold`.`dim_breed`
where breed_name is null



  
  
      
    ) dbt_internal_test