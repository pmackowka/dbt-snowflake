{#
	Starsza wersja variable_test.sql, zachowana jako materiał referencyjny ze scalenia dwóch
	przejść projektu. var("nazwa", "domyślna") - nadpisywalne przez --vars bez zmiany kodu.
	Uruchomienie: dbt run-operation learn_variables --profiles-dir . --vars '{user_name: Piotr}'
#}
{% macro learn_variables() %}

    {% set your_name_jinja = "Zoltan" %}
    {{ log("Hello " ~ your_name_jinja, info=True) }}

    {{ log("Hello dbt user " ~ var("user_name", "NO USERNAME IS SET!!") ~ "!", info=True) }}

    {% if var("in_test", False) %}
       {{ log("In test", info=True) }}
    {% else %}
       {{ log("NOT in test", info=True) }}
    {% endif %}

{% endmacro %}