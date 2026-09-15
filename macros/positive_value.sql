{#
	Generic test wielokrotnego użytku - kolumna nie może mieć wartości < 1. Użyty na
	dim_listings_cleansed.minimum_nights (models/schema.yml) jako refaktor starszego,
	pojedynczego testu tests/dim_listings_minumum_nights.sql (ten sam warunek, ale
	hardkodowany na jeden model/kolumnę) - ten drugi plik zostawiony jako punkt odniesienia,
	nie jest już potrzebny do działania testów.
#}
{% test positive_value(model, column_name) %}
SELECT
    *
FROM
    {{ model }}
WHERE
    {{ column_name}} < 1
{% endtest %}

{# Powyższe makro "positive_value" wielokrotnego użytku to refaktor dla models/tests/dim_listings_minumum_nights.sql, które moze zostać usunięte #}