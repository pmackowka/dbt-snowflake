{#
	Fakt: recenzje Airbnb, z wygenerowanym surrogate key (bo źródło nie ma naturalnego klucza
	głównego dla pojedynczej recenzji).

	materialized='incremental' - fct_reviews to typowa tabela faktów, rosnąca z czasem (każda nowa
	recenzja to nowy wiersz, stare recenzje się nie zmieniają) - przeliczanie całej historii przy
	każdym dbt run (materializacja 'table') byłoby marnowaniem czasu i kredytów warehouse'u na
	dane, które już raz policzono i które się nie zmienią.

	on_schema_change='fail', NIE 'sync_all_columns' (jak w siostrzanym repo dbt-bigquery, model
	stg_ecommerce__events.sql) - świadomie inny wybór: tam events to tabela WEWNĘTRZNA projektu,
	tu src_reviews pochodzi z surowej tabeli raw_reviews, której schemat może się zmienić bez
	uprzedzenia (np. przy kolejnym imporcie z S3 z innym zestawem kolumn). 'fail' celowo
	PRZERYWA build zamiast po cichu dostosować schemat - błąd ma być widoczny od razu, a nie
	ukryty za automatyczną synchronizacją, która mogłaby zamaskować realny problem ze źródłem.
#}
{{
  config(
    materialized = 'incremental',
    on_schema_change='fail'
    )
}}

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
  	Dwie ścieżki inkrementalnego ładowania - wybór między nimi zależy od tego, czy użytkownik
  	podał --vars przy wywołaniu dbt run:

  	1) start_date/end_date podane -> ręczny backfill KONKRETNEGO zakresu dat, niezależnie od
  	   tego, co już jest w tabeli. Przydatne np. gdy trzeba przeliczyć jeden miesiąc na nowo po
  	   znalezieniu błędu w danych źródłowych, bez --full-refresh całej tabeli (który przeliczyłby
  	   WSZYSTKO od zera, znacznie drożej i wolniej).
  	2) brak --vars (domyślne zachowanie) -> zwykły przyrost: tylko recenzje nowsze niż
  	   MAX(review_date) już obecny w tabeli.

  	log(..., info=True) w obu gałęziach wypisuje na ekran, KTÓRA ścieżka się wykonała - przydatne
  	przy debugowaniu, żeby nie zgadywać, czy --vars zostały poprawnie odczytane.
  #}
  {% if var("start_date", False) and var("end_date", False) %}
    {{ log('Loading ' ~ this ~ ' incrementally (start_date: ' ~ var("start_date") ~ ', end_date: ' ~ var("end_date") ~ ')', info=True) }}
    AND review_date >= '{{ var("start_date") }}'
    AND review_date < '{{ var("end_date") }}'
  {% else %}
    AND review_date > (select max(review_date) from {{ this }})
    {{ log('Loading ' ~ this ~ ' incrementally (all missing dates)', info=True)}}
  {% endif %}
{% endif %}
