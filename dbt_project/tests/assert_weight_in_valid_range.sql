-- No dog breed should weigh more than 120kg or less than 0.5kg.
-- Catches data corruption or parsing errors in the weight columns.
select
    breed_id,
    breed_name,
    avg_weight_kg
from {{ ref('fact_weight_life_span') }}
where avg_weight_kg < 0.5 or avg_weight_kg > 120
