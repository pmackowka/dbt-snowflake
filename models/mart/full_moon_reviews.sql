{#
	Mart: fct_reviews + seed_full_moon_dates - oznacza recenzje z nocy po pełni.
	table, nie view z projektu: mart czytają BI i analyses/, więc join liczy się raz na run,
	a nie przy każdym zapytaniu.
	Jawna lista kolumn zamiast r.*: kontrakt (models/schema.yml) i tak jej wymaga, a r.*
	przepuszczałby każdą nową kolumnę z fct_reviews prosto do dashboardu.
#}
{{ config(
  materialized = 'table',
) }}

WITH fct_reviews AS (
    SELECT * FROM {{ ref('fct_reviews') }}
),
full_moon_dates AS (
    SELECT * FROM {{ ref('seed_full_moon_dates') }}
)

SELECT
  r.review_id,
  r.listing_id,
  r.review_date,
  r.reviewer_name,
  r.review_text,
  r.review_sentiment,
  CASE
    WHEN fm.full_moon_date IS NULL THEN 'not full moon'
    ELSE 'full moon'
  END AS is_full_moon
FROM
  fct_reviews r
  LEFT JOIN full_moon_dates fm
  ON (TO_DATE(r.review_date) = DATEADD(DAY, 1, fm.full_moon_date))