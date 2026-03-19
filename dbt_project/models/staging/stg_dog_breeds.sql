{{
    config(
        materialized='view',
        schema='silver'
    )
}}

with source as (
    select * from {{ source('bronze', 'dog_api_raw') }}
),

cleaned as (
    select
        cast(id as int64) as breed_id,
        trim(name) as breed_name,
        trim(coalesce(breed_group, 'Unknown')) as breed_group,
        trim(coalesce(origin, 'Unknown')) as origin,
        trim(coalesce(temperament, '')) as temperament,
        {{ parse_range('life_span', 'life_span') }},
        {{ parse_range('weight__metric', 'weight_kg') }},
        {{ parse_range('height__metric', 'height_cm') }},
        coalesce(reference_image_id, '') as reference_image_id,
        _dlt_load_id as load_id,
        _dlt_id as dlt_row_id
    from source
)

select * from cleaned
