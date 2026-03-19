select
    breed_id,
    breed_name,
    life_span_min,
    life_span_max,
    avg_life_span_years
from {{ ref('dim_breed') }}
where avg_life_span_years < 0
