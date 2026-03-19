{{
    config(
        materialized='table',
        schema='gold'
    )
}}

with staged as (
    select * from {{ ref('stg_dog_breeds') }}
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
        round((coalesce(life_span_min, 0) + coalesce(life_span_max, 0)) / 2.0, 1) as avg_life_span_years,
        weight_kg_min,
        weight_kg_max,
        round((coalesce(weight_kg_min, 0) + coalesce(weight_kg_max, 0)) / 2.0, 1) as avg_weight_kg,
        height_cm_min,
        height_cm_max,
        round((coalesce(height_cm_min, 0) + coalesce(height_cm_max, 0)) / 2.0, 1) as avg_height_cm,
        case
            when (coalesce(weight_kg_min, 0) + coalesce(weight_kg_max, 0)) / 2.0 <= 10 then 'Small'
            when (coalesce(weight_kg_min, 0) + coalesce(weight_kg_max, 0)) / 2.0 <= 25 then 'Medium'
            when (coalesce(weight_kg_min, 0) + coalesce(weight_kg_max, 0)) / 2.0 <= 45 then 'Large'
            when (coalesce(weight_kg_min, 0) + coalesce(weight_kg_max, 0)) / 2.0 > 45 then 'Giant'
            else 'Unknown'
        end as size_class,
        reference_image_id
    from staged
)

select * from enriched
