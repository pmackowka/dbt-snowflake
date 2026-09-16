{#
	Snapshot SCD2 dla gospodarzy Airbnb - analogicznie do snapshots/scd_raw_listings.sql (patrz
	tam pełne wyjaśnienie SCD2, wyboru strategy='timestamp' i invalidate_hard_deletes), tu dla
	tabeli raw_hosts. Rozdzielony na osobny plik, bo `{% snapshot %}` obejmuje dokładnie jedną
	tabelę źródłową - nie da się śledzić dwóch różnych tabel w jednym bloku.

	target_schema='dev' (małe litery) - w scd_raw_listings.sql jest 'DEV' (duże litery). Snowflake
	normalizuje niecudzysłowione identyfikatory do wielkich liter, więc oba trafiają do TEGO
	SAMEGO schematu - niespójność w zapisie, nie w efekcie, zostawiona tak, jak była w oryginale.
#}
{% snapshot scd_raw_hosts %}

{{
   config(
       target_schema='dev',
       unique_key='id',
       strategy='timestamp',
       updated_at='updated_at',
       invalidate_hard_deletes=True
   )
}}

select * FROM {{ source('airbnb', 'hosts') }}

{% endsnapshot %}
