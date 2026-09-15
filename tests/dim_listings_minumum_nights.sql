{# Singular test (starszy, zastąpiony przez generic test macros/positive_value.sql - zostawiony jako punkt odniesienia): minimum_nights nie może być < 1 #}
SELECT
    *
FROM
    {{ ref('dim_listings_cleansed') }}
WHERE minimum_nights < 1
LIMIT 10