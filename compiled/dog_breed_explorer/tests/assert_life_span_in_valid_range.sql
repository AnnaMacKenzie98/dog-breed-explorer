-- No breed should have an average life span above 25 years or below 3 years.
-- Catches parsing errors or corrupted data in life span columns.
select
    breed_id,
    breed_name,
    avg_life_span_years
from `dog-breed-explorer-am`.`gold`.`fact_weight_life_span`
where avg_life_span_years < 3 or avg_life_span_years > 25