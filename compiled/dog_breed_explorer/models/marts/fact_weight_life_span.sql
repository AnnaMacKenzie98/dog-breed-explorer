

with staged as (
    select * from `dog-breed-explorer-am`.`silver`.`stg_dog_breeds`
),

facts as (
    select
        breed_id,
        breed_name,
        breed_group,
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
            when life_span_min is not null and life_span_max is not null
                and weight_kg_min is not null and weight_kg_max is not null
                and height_cm_min is not null and height_cm_max is not null then true
            else false
        end as has_complete_metrics
    from staged
    where
        coalesce(life_span_min, life_span_max) is not null
        or coalesce(weight_kg_min, weight_kg_max) is not null
)

select * from facts