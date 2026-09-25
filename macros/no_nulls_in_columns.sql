{#
	Test "brak NULL-i w żadnej kolumnie" bez wymieniania kolumn: get_columns_in_relation() czyta
	je z bazy i buduje col1 IS NULL OR ... OR FALSE. Zielony dbt parse nic tu nie dowodzi: przy
	parsowaniu makro dostaje pustą listę kolumn (@available.parse_list). Użycie: tests/no_nulls_in_dim_listings.sql.
#}
{% macro no_nulls_in_columns(model) %}
    SELECT * FROM {{ model }} WHERE
    {% for col in adapter.get_columns_in_relation(model) -%}
        {{ col.column }} IS NULL OR
    {% endfor %}
    FALSE
{% endmacro %}