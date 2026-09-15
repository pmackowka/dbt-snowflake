{#
	Makro typu 3 (operacja) - demonstruje mechanikę log() z notatki, sekcja 11.
	Uruchomienie: dbt run-operation learn_logging --profiles-dir .
	Kluczowa lekcja: komentarz SQL (--) NIE wyłącza logu, bo Jinja renderuje {{ }} na etapie
	kompilacji, zanim SQL w ogóle zobaczy --. Żeby faktycznie wyłączyć wywołanie, trzeba
	komentarza Jinja {# #} (patrz linia niżej).
#}
{% macro learn_logging() %}
    {{ log("Call your mom!") }}
    {{ log("Call your dad!", info=True) }} --> Logs to the screen, too
--  {{ log("Call your dad!", info=True) }} --> This will be put to the screen
    {# log("Call your dad!", info=True) #} --> This won't be executed
{% endmacro %}