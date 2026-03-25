
  
    

    create or replace table `dog-breed-explorer-am`.`gold`.`dim_breed`
      
    
    

    
    OPTIONS()
    as (
      

with staged as (
    select * from `dog-breed-explorer-am`.`silver`.`stg_dog_breeds`
),

enriched as (
    select
        breed_id,
        breed_name,
        breed_group,
        origin,
        temperament,
        split(temperament, ', ') as temperament_array,
        life_span_min,
        life_span_max,
        case
            when life_span_min is not null and life_span_max is not null
                then round((life_span_min + life_span_max) / 2.0, 1)
            else round(coalesce(life_span_min, life_span_max), 1)
        end as avg_life_span_years,
        weight_kg_min,
        weight_kg_max,
        case
            when weight_kg_min is not null and weight_kg_max is not null
                then round((weight_kg_min + weight_kg_max) / 2.0, 1)
            else round(coalesce(weight_kg_min, weight_kg_max), 1)
        end as avg_weight_kg,
        height_cm_min,
        height_cm_max,
        case
            when height_cm_min is not null and height_cm_max is not null
                then round((height_cm_min + height_cm_max) / 2.0, 1)
            else round(coalesce(height_cm_min, height_cm_max), 1)
        end as avg_height_cm,
        reference_image_id
    from staged
),

with_size_class as (
    select
        *,
        case
            when avg_weight_kg is null  then 'Unknown'
            when avg_weight_kg <= 10    then 'Small'
            when avg_weight_kg <= 25    then 'Medium'
            when avg_weight_kg <= 45    then 'Large'
            else 'Giant'
        end as size_class
    from enriched
)

select * from with_size_class
    );
  