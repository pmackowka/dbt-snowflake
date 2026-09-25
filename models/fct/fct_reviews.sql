{#
	Fakt: recenzje. review_id to surrogate key, bo źródło nie ma klucza pojedynczej recenzji.

	incremental: recenzje tylko przybywają, a pełny rebuild co run to kredyty za dane już policzone.
	unique_key='review_id': bez klucza MERGE nie ma warunku dopasowania i działa jak INSERT -
	backfill zakresu, który już jest w tabeli, dopisałby duplikaty. Z kluczem ponowne wczytanie
	wiersza to UPDATE. Siatką jest test unique na review_id (models/schema.yml).
	Ryzyko: dwie identyczne recenzje (oferta, data, autor, tekst) dają ten sam klucz i Snowflake
	przerywa MERGE (ERROR_ON_NONDETERMINISTIC_MERGE). Nie sprawdzone na danych.

	on_schema_change='fail': src_reviews wybiera kolumny jawnie, więc zmiana w raw_reviews tu nie
	dociera. 'fail' łapie zmianę kolumn w SAMYM modelu i wymusza świadome --full-refresh.
#}
{{
  config(
    materialized = 'incremental',
    unique_key = 'review_id',
    on_schema_change='fail'
    )
}}

{# Okno wsteczne: recenzja dociągnięta później z datą <= MAX(review_date) nie przepada. #}
{% set lookback_days = 3 %}

WITH src_reviews AS (
  SELECT * FROM {{ ref('src_reviews') }}
)
SELECT
  {{ dbt_utils.generate_surrogate_key(['listing_id', 'review_date', 'reviewer_name', 'review_text']) }} as review_id,
  *
FROM src_reviews
WHERE review_text is not null
{% if is_incremental() %}
  {#
  	--vars start_date/end_date: backfill konkretnego zakresu bez --full-refresh całej tabeli.
  	Bez --vars: przyrost od MAX(review_date) minus okno. MERGE nadal skanuje cały cel - przy
  	dużej tabeli dołożyć incremental_predicates z oknem >= lookback + dni przestoju. Za krótkie
  	okno: po przerwie MERGE nie znajdzie istniejących wierszy i wstawi duplikaty.
  	log(info=True) pokazuje, która ścieżka się wykonała.
  #}
  {% if var("start_date", False) and var("end_date", False) %}
    {{ log('Loading ' ~ this ~ ' incrementally (start_date: ' ~ var("start_date") ~ ', end_date: ' ~ var("end_date") ~ ')', info=True) }}
    AND review_date >= '{{ var("start_date") }}'
    AND review_date < '{{ var("end_date") }}'
  {% else %}
    AND review_date >= (select dateadd(day, -{{ lookback_days }}, max(review_date)) from {{ this }})
    {{ log('Loading ' ~ this ~ ' incrementally (all missing dates, lookback ' ~ lookback_days ~ ' days)', info=True)}}
  {% endif %}
{% endif %}
