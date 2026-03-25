
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        size_class as value_field,
        count(*) as n_records

    from `dog-breed-explorer-am`.`gold`.`dim_breed`
    group by size_class

)

select *
from all_values
where value_field not in (
    'Small','Medium','Large','Giant','Unknown'
)



  
  
      
    ) dbt_internal_test