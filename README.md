# dbt na Snowflake — Airbnb pipeline

Projekt dbt Core zbudowany w trakcie kursu Udemy *The Complete dbt Bootcamp* i rozszerzony o własne dodatki.
Dane: listings/hosts/reviews Airbnb, ładowane z S3 do Snowflake (`AIRBNB.RAW`).

## Struktura

```
models/src/        # src_* — ephemeral, jeden model na tabelę źródłową
models/dim/         # dim_* — wymiary (table)
models/fct/         # fct_reviews — fakt, incremental
models/mart/         # full_moon_reviews — finalna tabela biznesowa
models/documents/   # custom overview + doc() bloki dla dbt docs
seeds/               # seed_full_moon_dates.csv
snapshots/           # SCD2 dla listings i hosts (invalidate_hard_deletes)
tests/                # singular testy + wywołania generic testów
macros/               # positive_value, no_nulls_in_columns, logowanie/zmienne (operacje)
analyses/             # zapytania eksploracyjne (dbt compile, bez materializacji)
assets/               # obrazy osadzane w dbt docs (asset-paths)
```

## Co jest tu ponad materiał kursu

- **Governance przez `post-hook`**: `GRANT SELECT ... TO ROLE REPORTER` na każdym modelu automatycznie, zamiast ręcznego nadawania uprawnień po każdym `dbt run`.
- **`dbt_expectations` jako deep dive jakości danych** na `dim_listings_w_hosts`: porównanie liczby wierszy ze źródłem, kwantyle jako wykrywanie outlierów, `severity: warn` na wartościach ekstremalnych.
- **Parametryzowany backfill** `fct_reviews` przez `--vars '{start_date: ..., end_date: ...}'` zamiast tylko "od ostatniego maksimum".
- **Dwa warianty tego samego makra** logowania/zmiennych (`macros/logging.sql` + `macros/variable_test.sql`, `macros/learn_variables.sql`) zostawione celowo jako materiał referencyjny z dwóch przejść kursu.

## Setup

Autoryzacja: **para kluczy RSA (key-pair)**, nie hasło — to metoda, której oficjalne repo tego kursu (`nordquant/complete-dbt-bootcamp-zero-to-hero`) używa do provisioningu użytkownika serwisowego `dbt` (`TYPE=SERVICE`, `RSA_PUBLIC_KEY`). Klucz prywatny nie wygasa jak sesja logowania i działa wszędzie bez ponownego uwierzytelniania.

### 1. Snowflake — role, warehouse, użytkownik, import danych

**Wygeneruj parę kluczy RSA lokalnie** (klucz prywatny zostaje POZA folderem repo):

```bash
mkdir -p ~/.snowflake
openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out ~/.snowflake/rsa_key.p8 -nocrypt
openssl rsa -in ~/.snowflake/rsa_key.p8 -pubout -out ~/.snowflake/rsa_key.pub

# Klucz publiczny do wklejenia w SQL niżej - bez linii BEGIN/END i bez łamań linii
grep -v -- '-----' ~/.snowflake/rsa_key.pub | tr -d '\n'
```

**W konsoli Snowflake (Worksheet), jako `ACCOUNTADMIN`** — provisioning roli, warehouse'u i użytkownika serwisowego:

```sql
USE ROLE ACCOUNTADMIN;

CREATE WAREHOUSE IF NOT EXISTS COMPUTE_WH;

CREATE ROLE IF NOT EXISTS TRANSFORM;
GRANT ROLE TRANSFORM TO ROLE ACCOUNTADMIN;
GRANT OPERATE ON WAREHOUSE COMPUTE_WH TO ROLE TRANSFORM;

CREATE USER IF NOT EXISTS dbt
  LOGIN_NAME = 'dbt'
  TYPE = SERVICE
  RSA_PUBLIC_KEY = '<<wklej tu output z grep -v powyżej>>'
  DEFAULT_ROLE = TRANSFORM
  DEFAULT_WAREHOUSE = 'COMPUTE_WH'
  DEFAULT_NAMESPACE = 'AIRBNB.RAW'
  COMMENT = 'dbt user do transformacji danych';

GRANT ROLE TRANSFORM TO USER dbt;

CREATE DATABASE IF NOT EXISTS AIRBNB;
CREATE SCHEMA IF NOT EXISTS AIRBNB.RAW;
CREATE SCHEMA IF NOT EXISTS AIRBNB.DEV;

GRANT ALL ON WAREHOUSE COMPUTE_WH TO ROLE TRANSFORM;
GRANT ALL ON DATABASE AIRBNB TO ROLE TRANSFORM;
GRANT ALL ON ALL SCHEMAS IN DATABASE AIRBNB TO ROLE TRANSFORM;
GRANT ALL ON FUTURE SCHEMAS IN DATABASE AIRBNB TO ROLE TRANSFORM;
GRANT ALL ON ALL TABLES IN SCHEMA AIRBNB.RAW TO ROLE TRANSFORM;
GRANT ALL ON FUTURE TABLES IN SCHEMA AIRBNB.RAW TO ROLE TRANSFORM;
```

**Import surowych danych z S3** (publiczny bucket kursu, `USE ROLE TRANSFORM; USE DATABASE AIRBNB; USE SCHEMA RAW;` najpierw):

```sql
CREATE OR REPLACE TABLE raw_listings (
    id INTEGER, listing_url STRING, name STRING, room_type STRING,
    minimum_nights INTEGER, host_id INTEGER, price STRING,
    created_at DATETIME, updated_at DATETIME
);
COPY INTO raw_listings
  FROM 's3://dbt-datasets/listings.csv'
  FILE_FORMAT = (type = 'CSV' skip_header = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"');

CREATE OR REPLACE TABLE raw_hosts (
    id INTEGER, name STRING, is_superhost STRING,
    created_at DATETIME, updated_at DATETIME
);
COPY INTO raw_hosts
  FROM 's3://dbt-datasets/hosts.csv'
  FILE_FORMAT = (type = 'CSV' skip_header = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"');

CREATE OR REPLACE TABLE raw_reviews (
    listing_id INTEGER, date DATETIME, reviewer_name STRING,
    comments STRING, sentiment STRING
);
COPY INTO raw_reviews
  FROM 's3://dbt-datasets/reviews.csv'
  FILE_FORMAT = (type = 'CSV' skip_header = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"');
```

Rola `REPORTER` (odbiorca `post-hook` z `dbt_project.yml`, pod BI typu Preset/Superset — patrz `models/dashboards.yml`) jest opcjonalna do samego uruchomienia dbt; provisionuj ją tylko, jeśli faktycznie podłączasz narzędzie BI.

### 2. Repo i środowisko Python

```bash
git clone https://github.com/pmackowka/dbt-snowflake.git
cd dbt-snowflake

python3 -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt  # instaluje dbt-snowflake==1.12.0 (dociąga zgodny dbt-core)
```

### 3. Konfiguracja połączenia

```bash
cp profiles.yml.example profiles.yml   # profiles.yml jest w .gitignore - nigdy go nie commituj
export SNOWFLAKE_ACCOUNT="xy12345.us-east-2.aws"   # z URL-a konsoli Snowflake, przed .snowflakecomputing.com
export SNOWFLAKE_USER="dbt"
export SNOWFLAKE_PRIVATE_KEY_PATH="$HOME/.snowflake/rsa_key.p8"
export SNOWFLAKE_PRIVATE_KEY_PASSPHRASE=""   # puste, bo klucz wygenerowany z -nocrypt

dbt deps --profiles-dir .    # instaluje pakiety z packages.yml do dbt_packages/
dbt debug --profiles-dir .   # weryfikuje połączenie PRZED pierwszym run
```

### 4. Pierwszy build

```bash
dbt seed --profiles-dir .       # ładuje seeds/seed_full_moon_dates.csv (dbt run tego NIE robi)
dbt snapshot --profiles-dir .   # pierwszy przebieg snapshotów SCD2 (scd_raw_listings, scd_raw_hosts)
dbt build --profiles-dir .      # seed + snapshot + run + test w jednym poleceniu, kolejność wg DAG-a
```

`dbt build` przy kolejnych uruchomieniach wystarcza sam. Backfill konkretnego zakresu dat w `fct_reviews`:

```bash
dbt run --select fct_reviews --vars '{start_date: "2024-02-15 00:00:00", end_date: "2024-03-15 23:59:59"}' --profiles-dir .
```

## Notatki (prywatne, tylko dla mnie)

Pełne notatki merytoryczne z kursu (Analyses/Hooks/Exposures, debugging przez `dbt-expectations`, logowanie, zmienne, orkiestracja Dagster) są w moim prywatnym repo wiedzy: [dbt-Snowflake-i-Orkiestracja-Dagster.md](https://github.com/pmackowka/knowledge-base/blob/main/wiki/Software/dbt/dbt-Snowflake-i-Orkiestracja-Dagster.md).

Ten link **działa tylko na moim koncie GitHub** — repo jest prywatne i takie zostanie. Dla każdego innego zwraca 404, to celowe, nie błąd.
