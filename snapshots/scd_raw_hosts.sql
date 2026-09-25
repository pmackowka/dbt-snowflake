{#
	Snapshot SCD2 gospodarzy - mechanika i wybory jak w scd_raw_listings.sql, łącznie z kolizją
	dev/prod przez target_schema. Osobny plik, bo blok snapshot obejmuje jedną tabelę źródłową.
	'dev' małymi literami trafia do tego samego schematu co 'DEV': Snowflake normalizuje
	niecudzysłowione identyfikatory do wielkich liter.
#}
{% snapshot scd_raw_hosts %}

{{
   config(
       target_schema='dev',
       unique_key='id',
       strategy='timestamp',
       updated_at='updated_at',
       hard_deletes='invalidate'
   )
}}

select * FROM {{ source('airbnb', 'hosts') }}

{% endsnapshot %}
