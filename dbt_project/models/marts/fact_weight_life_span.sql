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
        case
            when life_span_min is not null and life_span_max is not null
                then round(life_span_max - life_span_min, 1)
            else null
        end as life_span_range_years,
        case
            when weight_kg_min is not null and weight_kg_max is not null
                then round(weight_kg_max - weight_kg_min, 1)
            else null
        end as weight_range_kg,
        case
            when life_span_min is not null and weight_kg_min is not null and height_cm_min is not null then true
            else false
        end as has_complete_metrics
    from breeds
    where avg_life_span_years is not null or avg_weight_kg is not null
)

select * from facts
