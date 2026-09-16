{#
	Snapshot SCD2 (Slowly Changing Dimension typu 2) dla ofert Airbnb - każda zmiana w
	raw_listings (np. host zmienia cenę albo nazwę oferty) tworzy nowy wiersz z własnym okresem
	ważności w OSOBNEJ, rosnącej tabeli historii, zamiast nadpisywać poprzednią wartość. dbt
	dokłada automatycznie kolumny techniczne dbt_scd_id, dbt_updated_at, dbt_valid_from,
	dbt_valid_to (NULL = wersja aktualna). Uruchamiane WYŁĄCZNIE przez `dbt snapshot`.

	strategy='timestamp', NIE 'check' (jak w siostrzanym repo dbt-bigquery, snapshot
	distribution_centers) - świadomie inny wybór: raw_listings MA kolumnę updated_at, więc dbt
	może po prostu porównać znacznik czasu z ostatnim snapshotem zamiast wartość po wartości
	sprawdzać każdą kolumnę biznesową. Tańsze obliczeniowo i nie trzeba pamiętać o dopisaniu
	nowej kolumny do check_cols za każdym razem, gdy do listings dojdzie nowe pole.

	invalidate_hard_deletes=True - jeśli oferta zniknie ze źródła przez FIZYCZNY DELETE (nie
	tylko zmianę pola), snapshot oznacza jej ostatnią wersję jako nieaktualną (ustawia
	dbt_valid_to) zamiast zostawiać ją wiecznie "aktualną" mimo braku w źródle. Bez tego
	usunięta oferta wyglądałaby w historii tak, jakby nadal obowiązywała.
#}
{% snapshot scd_raw_listings %}

{{
   config(
       target_schema='DEV',
       unique_key='id',
       strategy='timestamp',
       updated_at='updated_at',
       invalidate_hard_deletes=True
   )
}}

select * FROM {{ source('airbnb', 'listings') }}

{% endsnapshot %}
