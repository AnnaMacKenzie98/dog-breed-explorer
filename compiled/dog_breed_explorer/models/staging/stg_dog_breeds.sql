

with source as (
    select * from `dog-breed-explorer-am`.`bronze`.`dog_api_raw`
),

cleaned as (
    select
        cast(id as int64) as breed_id,
        trim(name) as breed_name,
        trim(coalesce(breed_group, 'Unknown')) as breed_group,
        trim(coalesce(origin, 'Unknown')) as origin,
        trim(coalesce(temperament, '')) as temperament,
        

safe_cast(
    nullif(trim(split(regexp_replace(life_span, r'[^0-9\.\- ]', ''), '-')[safe_offset(0)]), '')
    as float64
) as life_span_min,

safe_cast(
    nullif(trim(
        coalesce(
            split(regexp_replace(life_span, r'[^0-9\.\- ]', ''), '-')[safe_offset(1)],
            split(regexp_replace(life_span, r'[^0-9\.\- ]', ''), '-')[safe_offset(0)]
        )
    ), '')
    as float64
) as life_span_max

,
        

safe_cast(
    nullif(trim(split(regexp_replace(weight__metric, r'[^0-9\.\- ]', ''), '-')[safe_offset(0)]), '')
    as float64
) as weight_kg_min,

safe_cast(
    nullif(trim(
        coalesce(
            split(regexp_replace(weight__metric, r'[^0-9\.\- ]', ''), '-')[safe_offset(1)],
            split(regexp_replace(weight__metric, r'[^0-9\.\- ]', ''), '-')[safe_offset(0)]
        )
    ), '')
    as float64
) as weight_kg_max

,
        

safe_cast(
    nullif(trim(split(regexp_replace(height__metric, r'[^0-9\.\- ]', ''), '-')[safe_offset(0)]), '')
    as float64
) as height_cm_min,

safe_cast(
    nullif(trim(
        coalesce(
            split(regexp_replace(height__metric, r'[^0-9\.\- ]', ''), '-')[safe_offset(1)],
            split(regexp_replace(height__metric, r'[^0-9\.\- ]', ''), '-')[safe_offset(0)]
        )
    ), '')
    as float64
) as height_cm_max

,
        coalesce(reference_image_id, '') as reference_image_id,
        _dlt_load_id as load_id,
        _dlt_id as dlt_row_id
    from source
)

select * from cleaned