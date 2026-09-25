{#
	Makro typu 3 (operacja) - starsza, krótsza wersja macros/variable_test.sql, zachowana jako
	materiał referencyjny ze scalenia dwóch przejść projektu (razem z assets/). Demonstruje var("nazwa", "domyślna") - wartość
	nadpisywalna z CLI (--vars) bez zmiany kodu makra.
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