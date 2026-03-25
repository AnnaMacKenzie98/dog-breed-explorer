
    
    

with dbt_test__target as (

  select breed_id as unique_field
  from `dog-breed-explorer-am`.`silver`.`stg_dog_breeds`
  where breed_id is not null

)

select
    unique_field,
    count(*) as n_records

from dbt_test__target
group by unique_field
having count(*) > 1


