select
    breed_id,
    breed_name,
    life_span_min,
    life_span_max,
    avg_life_span_years
from {{ ref('fact_weight_life_span') }}
where avg_life_span_years < 0
