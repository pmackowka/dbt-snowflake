{#
	Snapshot SCD2 ofert: każda zmiana w raw_listings to nowy wiersz z okresem ważności
	(dbt_valid_from/dbt_valid_to, NULL = wersja aktualna), zamiast nadpisania. Uruchamia go
	`dbt snapshot` i `dbt build` (pomija tylko `dbt run`).

	strategy='timestamp': źródło ma updated_at, więc dbt porównuje jeden znacznik czasu zamiast
	każdej kolumny (check_cols) i nie trzeba dopisywać nowych pól do listy.
	hard_deletes='invalidate': fizycznie usunięta oferta dostaje dbt_valid_to, zamiast wiecznie
	wyglądać na aktualną.

	UWAGA - kolizja dev/prod: target_schema jest brany dosłownie, bez prefiksu target.schema.
	Manifest przy --target prod: AIRBNB.DEV.scd_raw_listings - dev i prod piszą do TEJ SAMEJ
	historii. Świadomie niezmienione: zmiana schematu porzuca zebraną historię SCD2. Naprawa
	przy uruchomieniu prod: schema='snapshots' (-> <target.schema>_SNAPSHOTS) + migracja tabeli.
#}
{% snapshot scd_raw_listings %}

{{
   config(
       target_schema='DEV',
       unique_key='id',
       strategy='timestamp',
       updated_at='updated_at',
       hard_deletes='invalidate'
   )
}}

select * FROM {{ source('airbnb', 'listings') }}

{% endsnapshot %}
