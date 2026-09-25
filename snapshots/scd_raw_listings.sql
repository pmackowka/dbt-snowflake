{#
	Snapshot SCD2 ofert: każda zmiana w raw_listings to nowy wiersz z okresem ważności
	(dbt_valid_from/dbt_valid_to, NULL = wersja aktualna), zamiast nadpisania. Uruchamia go
	`dbt snapshot` i `dbt build` (pomija tylko `dbt run`).

	strategy='timestamp': źródło ma updated_at, więc dbt porównuje jeden znacznik czasu zamiast
	każdej kolumny (check_cols) i nie trzeba dopisywać nowych pól do listy.
	hard_deletes='invalidate': fizycznie usunięta oferta dostaje dbt_valid_to, zamiast wiecznie
	wyglądać na aktualną.

	schema, nie target_schema: target_schema jest brany dosłownie, więc dev i prod pisały do
	tej samej historii (AIRBNB.DEV). schema przechodzi przez generate_schema_name i dostaje
	prefiks środowiska: DEV_SNAPSHOTS / PROD_SNAPSHOTS.
#}
{% snapshot scd_raw_listings %}

{{
   config(
       schema='snapshots',
       unique_key='id',
       strategy='timestamp',
       updated_at='updated_at',
       hard_deletes='invalidate'
   )
}}

select * FROM {{ source('airbnb', 'listings') }}

{% endsnapshot %}
