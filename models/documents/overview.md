<!-- Custom overview page - nadpisuje domyślną stronę główną wygenerowanej dokumentacji
     (dbt docs generate && dbt docs serve). Obraz z assets/ (asset-paths w dbt_project.yml). -->
{% docs __overview__ %}
# Airbnb pipeline

Hey, welcome to our Airbnb pipeline documentation!

Here is the schema of our input data:
![input schema](assets/input_schema.png)

{% enddocs %}