-- Ensures the pipeline loaded a reasonable number of breeds.
-- The Dog API returns ~170 breeds; fewer than 100 indicates a data issue.
select count(*) as row_count
from {{ ref('stg_dog_breeds') }}
having count(*) < 100
