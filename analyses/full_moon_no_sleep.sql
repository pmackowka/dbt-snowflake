{# Analysis (tylko dbt compile, bez materializacji): sentyment recenzji w podziale na pełnię/nie-pełnię #}
WITH fullmoon_reviews AS (
    SELECT * FROM {{ ref('full_moon_reviews') }}
)
SELECT
    is_full_moon,
    review_sentiment,
    COUNT(*) as reviews
FROM
    fullmoon_reviews
GROUP BY
    is_full_moon,
    review_sentiment
ORDER BY
    is_full_moon,
    review_sentiment