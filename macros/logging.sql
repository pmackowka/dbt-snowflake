{#
	Makro-operacja: mechanika log(). Uruchomienie: dbt run-operation learn_logging
	Komentarz SQL (--) NIE wyłącza {{ }}: Jinja renderuje przed SQL-em. Wyłącza tylko {# #}.
#}
{% macro learn_logging() %}
    {{ log("Call your mom!") }}                              -- tylko do logs/dbt.log
    {{ log("Call your dad!", info=True) }}                    -- do logu ORAZ na ekran (info=True)
--  {{ log("Call your dad!", info=True) }}                    -- i tak wyświetli się na ekranie -
                                                                -- komentarz SQL (--) nie wyłącza Jinja
    {# log("Call your dad!", info=True) #}                    -- to jedyny sposób, żeby NIE wykonać
{% endmacro %}