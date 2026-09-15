{# Singular test wywołujący macros/no_nulls_in_columns.sql: żadna kolumna dim_listings_cleansed nie może być NULL #}
{{ no_nulls_in_columns(ref('dim_listings_cleansed')) }}