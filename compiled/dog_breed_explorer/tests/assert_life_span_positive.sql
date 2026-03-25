select
    breed_id,
    breed_name,
    life_span_min,
    life_span_max,
    avg_life_span_years
from `dog-breed-explorer-am`.`gold`.`fact_weight_life_span`
where avg_life_span_years < 0