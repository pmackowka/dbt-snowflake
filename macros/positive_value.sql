{#
	Generic test: wartość < 1 to błąd. Refaktor singular testu tests/dim_listings_minumum_nights.sql
	(ten sam warunek na sztywno dla jednej kolumny) - tamten zostaje jako punkt odniesienia.
#}
{% test positive_value(model, column_name) %}
SELECT
    *
FROM
    {{ model }}
WHERE
    {{ column_name}} < 1
{% endtest %}