{#
	Mart: fct_reviews + seed_full_moon_dates - oznacza recenzje z nocy po pełni.

	materialized='table', nie odziedziczone 'view' z projektu: to finalna tabela biznesowa
	(mart), do której docelowo sięga analiza w analyses/full_moon_no_sleep.sql i BI - fizyczna
	tabela czyta się od razu, bez przeliczania joina z fct_reviews i seedem przy każdym
	zapytaniu. Koszt (jedno przeliczenie przy dbt run) jest niższy niż powtarzalny koszt
	wielokrotnego odpytywania widoku przez kogoś, kto analizuje te dane.
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
  r.*,
  CASE
    WHEN fm.full_moon_date IS NULL THEN 'not full moon'
    ELSE 'full moon'
  END AS is_full_moon
FROM
  fct_reviews r
  LEFT JOIN full_moon_dates fm
  ON (TO_DATE(r.review_date) = DATEADD(DAY, 1, fm.full_moon_date))