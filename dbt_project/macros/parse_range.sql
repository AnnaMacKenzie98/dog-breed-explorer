{% macro parse_range(column_name, output_prefix) %}

safe_cast(
    nullif(trim(split(regexp_replace({{ column_name }}, r'[^0-9\.\- ]', ''), '-')[safe_offset(0)]), '')
    as float64
) as {{ output_prefix }}_min,

safe_cast(
    nullif(trim(
        coalesce(
            split(regexp_replace({{ column_name }}, r'[^0-9\.\- ]', ''), '-')[safe_offset(1)],
            split(regexp_replace({{ column_name }}, r'[^0-9\.\- ]', ''), '-')[safe_offset(0)]
        )
    ), '')
    as float64
) as {{ output_prefix }}_max

{% endmacro %}
