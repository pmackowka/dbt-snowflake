# CLAUDE.md — dbt-snowflake

Projekt dbt Core (Snowflake) z kursu Udemy *The Complete dbt Bootcamp*, rozszerzony o własne dodatki. Dane: Airbnb (listings/hosts/reviews), ładowane z S3 do `AIRBNB.RAW`. Pełny opis i lista własnych rozszerzeń ponad materiał kursu → [README.md](README.md).

## Setup i komendy

```bash
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt          # dbt-snowflake==1.12.0

cp profiles.yml.example profiles.yml     # profiles.yml jest w .gitignore, nigdy nie commitować
export SNOWFLAKE_ACCOUNT="..." SNOWFLAKE_USER="dbt" SNOWFLAKE_PRIVATE_KEY_PATH="..."

dbt deps --profiles-dir .
dbt parse --profiles-dir .               # weryfikacja bez połączenia ze Snowflake
dbt build --profiles-dir .               # seed + snapshot + run + test, wymaga żywego połączenia
```

Pełny provisioning Snowflake (rola/warehouse/user/RSA key/import z S3) → README.md sekcja Setup.

## Struktura

```
models/src/        src_*         — ephemeral, jeden model na tabelę źródłową
models/dim/         dim_*         — wymiary (table)
models/fct/         fct_reviews   — fakt, incremental
models/mart/         full_moon_reviews — finalna tabela biznesowa
seeds/                            — seed_full_moon_dates.csv
snapshots/                        — SCD2 dla listings/hosts
tests/                            — singular + wywołania generic testów
macros/                           — positive_value, no_nulls_in_columns, logowanie/zmienne
analyses/                         — SQL eksploracyjny, tylko dbt compile
assets/                           — obrazy w dbt docs (asset-paths)
```

Nazwa profilu i projektu: `snowflake_project` (NIE zmieniać na `dbt_snowflake` — ta nazwa koliduje z wewnętrznym pakietem makr adaptera dbt-snowflake, ten sam mechanizm co `dbt_bigquery` w siostrzanym repo).

## Historia repo — ważne dla kontekstu

To repo powstało 2026-09 z podziału większego monorepo `pmackowka/dbt` (dwa kursy dbt + kilka projektów firmowych). Siostrzane repo z pierwszego kursu (BigQuery, dataset e-commerce): [pmackowka/dbt-bigquery](https://github.com/pmackowka/dbt-bigquery), lokalnie `~/Documents/dev/dbt-bigquery` — ten sam wzorzec konsolidacji, nagłówków i README, warto trzymać oba repo spójne stylistycznie.

Ten projekt to scalenie dwóch przejść tego samego kursu: nowsza wersja (dbt-snowflake 1.9.2, exposures, `documents/`) plus `assets/` i `macros/learn_variables.sql` ze starszej wersji, zachowane jako materiał referencyjny (nie duplikat do wyczyszczenia).

Notatki merytoryczne z kursu (Analyses/Hooks/Exposures, debugging `dbt-expectations`, logowanie, zmienne, Dagster) są w osobnym repo wiedzy, nie tutaj — `knowledge-base/wiki/Software/dbt/dbt-Snowflake-i-Orkiestracja-Dagster.md`.

## Konwencje

- Kod i nazwy po angielsku, komentarze po polsku (zgodnie z globalnym stylem użytkownika).
- `profiles.yml` i klucz prywatny RSA nigdy nie trafiają do repo — tylko `profiles.yml.example` z `env_var()`, klucz trzymany poza folderem repo (`~/.snowflake/`).
- Repo jest prywatne; przy zmianie na publiczne sprawdzić jeszcze raz, czy nie wchodzą dane wrażliwe (już raz znalezione i wyczyszczone: prawdziwie wyglądający URL dashboardu i e-mail w `models/dashboards.yml`, zgenericyzowane).
