{#
	Snapshot SCD2 gospodarzy - mechanika i wybory (łącznie ze schematem per środowisko) jak
	w scd_raw_listings.sql. Osobny plik, bo blok snapshot obejmuje jedną tabelę źródłową.
#}
{% snapshot scd_raw_hosts %}

{{
   config(
       schema='snapshots',
       unique_key='id',
       strategy='timestamp',
       updated_at='updated_at',
       hard_deletes='invalidate'
   )
}}

select * FROM {{ source('airbnb', 'hosts') }}

{% endsnapshot %}
