{#
	Makro typu 3 (operacja) - demonstruje mechanikę log().
	Uruchomienie: dbt run-operation learn_logging --profiles-dir .
	Kluczowa lekcja: komentarz SQL (--) NIE wyłącza logu, bo Jinja renderuje {{ }} na etapie
	kompilacji, zanim SQL w ogóle zobaczy --. Żeby faktycznie wyłączyć wywołanie, trzeba
	komentarza Jinja {# #} (patrz linia niżej).
#}
{% macro learn_logging() %}
    {{ log("Call your mom!") }}                              -- tylko do logs/dbt.log
    {{ log("Call your dad!", info=True) }}                    -- do logu ORAZ na ekran (info=True)
--  {{ log("Call your dad!", info=True) }}                    -- i tak wyświetli się na ekranie -
                                                                -- komentarz SQL (--) nie wyłącza Jinja
    {# log("Call your dad!", info=True) #}                    -- to jedyny sposób, żeby NIE wykonać
{% endmacro %}