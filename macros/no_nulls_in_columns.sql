{#
	Makro typu 1 (używane wewnątrz testu SQL) - generuje test "brak NULL-i w żadnej kolumnie"
	bez ręcznego wymieniania kolumn: adapter.get_columns_in_relation() czyta metadane kolumn
	modelu w czasie kompilacji i buduje warunek col1 IS NULL OR col2 IS NULL OR ... OR FALSE.
	Użycie jako singular test: tests/no_nulls_in_dim_listings.sql.
#}
{% macro no_nulls_in_columns(model) %}
    SELECT * FROM {{ model }} WHERE
    {% for col in adapter.get_columns_in_relation(model) -%}
        {{ col.column }} IS NULL OR
    {% endfor %}
    FALSE
{% endmacro %}