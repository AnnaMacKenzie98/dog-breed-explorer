{{
    config(
        materialized='table',
        schema='gold'
    )
}}

with breeds as (
    select * from {{ ref('dim_breed') }}
),

facts as (
    select
        breed_id,
        breed_name,
        breed_group,
        size_class,
        life_span_min,
        life_span_max,
        avg_life_span_years,
        weight_kg_min,
        weight_kg_max,
        avg_weight_kg,
        height_cm_min,
        height_cm_max,
        avg_height_cm,
        coalesce(life_span_max, 0) - coalesce(life_span_min, 0) as life_span_range_years,
        coalesce(weight_kg_max, 0) - coalesce(weight_kg_min, 0) as weight_range_kg,
        case
            when life_span_min is not null and weight_kg_min is not null and height_cm_min is not null then true
            else false
        end as has_complete_metrics
    from breeds
    where avg_life_span_years > 0 or avg_weight_kg > 0
)

select * from facts
