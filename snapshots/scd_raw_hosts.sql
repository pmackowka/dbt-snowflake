{# Snapshot SCD2, strategia timestamp + invalidate_hard_deletes: śledzi zmiany raw_hosts w czasie #}
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