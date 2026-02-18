# Local DBT

## Setup

### Dependencies

Installing duckdb cli-tool:
```bash
curl https://install.duckdb.org | sh
```


Create virtual environment with `uv` and install `duckdb` packages in it:
```bash
uv venv dbt-env
source dbt-env/bin/activate
# The database
uv pip install duckdb

# The dbt connection to duckdb (also includes dbt-core)
uv pip install dbt-duckdb
```

### Project Setup

Create dbt project
```bash
dbt init taxi_rides_26
```

Select: `duckdb`


Now that the dbt project is created there will also be `~/.dbt/profiles.yaml` created (or extended if not the first project).

To configure the project, this can be used:
```yaml
taxi_rides_ny:
  target: dev
  outputs:
    # DuckDB Development profile
    dev:
      type: duckdb
      path: taxi_rides_26.duckdb
      schema: dev
      threads: 1
      extensions:
        - parquet
      settings:
        memory_limit: '2GB'
        preserve_insertion_order: false

    # DuckDB Production profile
    prod:
      type: duckdb
      path: taxi_rides_26.duckdb
      schema: prod
      threads: 1
      extensions:
        - parquet
      settings:
        memory_limit: '2GB'
        preserve_insertion_order: false

# Troubleshooting:
# - If you have less than 4GB RAM, try setting memory_limit to '1GB'
# - If you have 16GB+ RAM, you can increase to '4GB' for faster builds
# - Expected build time: 5-10 minutes on most systems
```

Now that your dbt profile is configured, let's load the taxi data into DuckDB. Navigate to the dbt project directory and run the ingestion script

```bash
cd taxi_rides_26/
touch ingest.py
```

<details>

<summary><b>ingest.py</b></summary>

```python
import duckdb
import requests
from pathlib import Path

BASE_URL = "https://github.com/DataTalksClub/nyc-tlc-data/releases/download"

def download_and_convert_files(taxi_type):
    data_dir = Path("data") / taxi_type
    data_dir.mkdir(exist_ok=True, parents=True)

    for year in [2019, 2020]:
        for month in range(1, 13):
            parquet_filename = f"{taxi_type}_tripdata_{year}-{month:02d}.parquet"
            parquet_filepath = data_dir / parquet_filename

            if parquet_filepath.exists():
                print(f"Skipping {parquet_filename} (already exists)")
                continue

            # Download CSV.gz file
            csv_gz_filename = f"{taxi_type}_tripdata_{year}-{month:02d}.csv.gz"
            csv_gz_filepath = data_dir / csv_gz_filename

            response = requests.get(f"{BASE_URL}/{taxi_type}/{csv_gz_filename}", stream=True)
            response.raise_for_status()

            with open(csv_gz_filepath, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)

            print(f"Converting {csv_gz_filename} to Parquet...")
            con = duckdb.connect()
            con.execute(f"""
                COPY (SELECT * FROM read_csv_auto('{csv_gz_filepath}'))
                TO '{parquet_filepath}' (FORMAT PARQUET)
            """)
            con.close()

            # Remove the CSV.gz file to save space
            csv_gz_filepath.unlink()
            print(f"Completed {parquet_filename}")

def update_gitignore():
    gitignore_path = Path(".gitignore")

    # Read existing content or start with empty string
    content = gitignore_path.read_text() if gitignore_path.exists() else ""

    # Add data/ if not already present
    if 'data/' not in content:
        with open(gitignore_path, 'a') as f:
            f.write('\n# Data directory\ndata/\n' if content else '# Data directory\ndata/\n')

if __name__ == "__main__":
    # Update .gitignore to exclude data directory
    update_gitignore()

    for taxi_type in ["yellow", "green"]:
        download_and_convert_files(taxi_type)

    con = duckdb.connect("taxi_rides_26.duckdb")
    con.execute("CREATE SCHEMA IF NOT EXISTS prod")

    for taxi_type in ["yellow", "green"]:
        con.execute(f"""
            CREATE OR REPLACE TABLE prod.{taxi_type}_tripdata AS
            SELECT * FROM read_parquet('data/{taxi_type}/*.parquet', union_by_name=true)
        """)

    con.close()
```

</details>

Run the script:
```bash
python3 ingest.py
```

Open the duckdb ui to look into the database:
```bash
duckdb -ui
```

The ui is accessable here:
```
┌──────────────────────────────────────┐
│                result                │
│               varchar                │
├──────────────────────────────────────┤
│ UI started at http://localhost:4213/ │
└──────────────────────────────────────┘
```

To Create new notebook and attach the database and query the db.

Now the ui can be closed and dbt connection to it can be tested:

```bash
dbz debug
```


## dbt Project Structure

### 📂 analyses
- Place for sql scripts that are not sharable but good to have a around
- Can used for data quality reports (internal use)
- Often unused

### 📂 data
- Directory where data can be saved to

### 📄 dbt_project.yml
- Most important dbt file
- Configures entire project
- Is used when you run a `dbt` cli command
- For `dbt-core` the profile should match the one in the `.dbt/profiles.yaml`

### 📂 macros
- Used to store macros that can be applied on tables / views (reusable logic)
- Help encapsulate logic in one place

### 📄 REAMDE.md
- Documentation of the projcet
- Installation / setup guides etc.


### 📂 seeds
- Folder to upload csv amd flat files (to add them to dbt later)
- Quick and dirty approach

### 📂 snapshots
- Takes a "picture" of a table of a table at a moment in time
- Useful to track history of a column that overwrites itself

### 📂 tests
- Place to put assertions in SQL-format
- Place for singular tests
- dbt builds fail if tests fail

### 📂 models
- dbt suggests 3 subfolters

#### 📂 staging
- Sources (raw table from database)
- Staging files are 1-to-1 copy of data with minimal cleaning steps
  - Data type change
  - Renaming columns
  - Removing columns that are "bad"
  - ...

#### 📂 intermediate

- Anything that is not raw or you dont want to expose
- No guidelines, just nice for heave duty cleaning of complex logic

#### 📂 marts
- If data is in marts, it is ready for "consumption"
- Tables ready for dashboards
- Properly modeled, clean tables


## dbt Sources

Step where you tell your dbt Project where to get the data from. 

Create `staging/` folder and `sources.yaml`:
```bash
cd taxi_rides_26/models
mkdir -p staging
cd staging
touch sources.yaml
```

<details>

<summary><b>sources.yaml</b></summary>

```yaml
version: 2

sources:
  - name: raw_data
    description: "Raw data source for NYC taxi rides"
    database: taxi_rides_26 # Google BQ: Project ID
    schema: prod            # Google BQ: Dataset name
    tables:                 # Google BQ: Table name
      - name: yellow_tripdata
      - name: green_tripdata
```

</details>


Create first SQL file:

```bash
# in `staging` folder ("stg" for staging table)
touch stg_green_tripdata.sql
```

This file should do as much cleaning as possible. For this you should:

- Group the columns by relevant categories
- Use sensible aliases for columns
- Cast columns to desired datatype

<details>

<summary><b>stg_green_tripdata.sql</b></summary>

```sql
SELECT
    -- identifiers
    CAST(vendorid AS INTEGER) AS vendor_id,
    CAST(ratecodeid AS INTEGER) AS rate_code_id,
    CAST(pulocationid AS INTEGER) AS pickup_location_id,
    CAST(dolocationid AS INTEGER) AS dropoff_location_id,

    -- timestamps
    CAST(lpep_pickup_datetime AS TIMESTAMP) AS pickup_datetime,
    CAST(lpep_dropoff_datetime AS TIMESTAMP) AS dropoff_datetime,

    -- trip info
    store_and_fwd_flag,
    CAST(passenger_count AS INTEGER),
    CAST(trip_distance AS FLOAT),
    CAST(trip_type AS INTEGER),

    -- payment info
    CAST(fare_amount AS NUMERIC),
    CAST(extra AS NUMERIC),
    CAST(mta_tax AS NUMERIC),
    CAST(tip_amount AS NUMERIC),
    CAST(tolls_amount AS NUMERIC),
    CAST(improvement_surcharge AS NUMERIC),
    CAST(total_amount AS NUMERIC),
    CAST(payment_type AS INTEGER)
FROM
    {{ source('raw_data', 'green_tripdata') }}
WHERE
    vendor_id IS NOT NULL;
```

</details>

<details>

<summary><b>stg_yellow_tripdata.sql</b></summary>

```sql
SELECT
    -- identifiers (standardized naming for consistency across yellow/green)
    CAST(vendorid AS INTEGER) AS vendor_id,
    CAST(ratecodeid AS INTEGER) AS rate_code_id,
    CAST(pulocationid AS INTEGER) AS pickup_location_id,
    CAST(dolocationid AS INTEGER) AS dropoff_location_id,

    -- timestamps (standardized naming)
    CAST(tpep_pickup_datetime AS timestamp) AS pickup_datetime,  -- tpep = Taxicab Passenger Enhancement Program (yellow taxis)
    CAST(tpep_dropoff_datetime AS timestamp) AS dropoff_datetime,

    -- trip info
    CAST(store_and_fwd_flag AS string) AS store_and_fwd_flag,
    CAST(passenger_count AS INTEGER) AS passenger_count,
    CAST(trip_distance AS NUMERIC) AS trip_distance,

    -- payment info
    CAST(fare_amount AS NUMERIC) AS fare_amount,
    CAST(extra AS NUMERIC) AS extra,
    CAST(mta_tax AS NUMERIC) AS mta_tax,
    CAST(tip_amount AS NUMERIC) AS tip_amount,
    CAST(tolls_amount AS NUMERIC) AS tolls_amount,
    CAST(improvement_surcharge AS NUMERIC) AS improvement_surcharge,
    CAST(total_amount AS NUMERIC) AS total_amount,
    CAST(payment_type AS INTEGER) AS payment_type
FROM
    {{ source('raw_data', 'yellow_tripdata') }}
WHERE
    vendor_id IS NOT NULL;
```

</details>

## dbt Models

Create `models/marts/` directory

```bash
mkdir -p taxi_rides_26/models/marts/reporting/
```

Create model:
```
touch -p taxi_rides_26/models/marts/reporting/monthly_revenue_by_location.py
```

### Important Model types

- **Dimension tables**: 
  - Descriptive reference data about business entities (who, what, where, when) - e.g., customers, products, locations, dates.

- **Fact tables**:
  - Measurable numeric data (metrics/events) with foreign keys linking to dimensions - e.g., sales transactions, page views, orders.


Create tables in the `models/marts/` directory:

```bash
touch dim_vendors.sql 
touch dim_locations.sql
```

Union of green and yellow data will be done in an intermediate model, for which a folder is created in the `models` directory:

```bash
mkdir intermediate
cd intermediate
# Create intermediate model
touch int_trips_unioned.sql
```



## dbt Seeds and Macros

Go to `seeds` folder and download the `taxi_zone_lookup.csv`:
```bash
wget -c https://github.com/DataTalksClub/data-engineering-zoomcamp/raw/refs/heads/main/04-analytics-engineering/taxi_rides_ny/seeds/taxi_zone_lookup.csv
```

Seed the table to make it accessible as dbt model:
```bash
dbt seed
```

To consider:

- Dont push large datasets to git
- Dont have confidential data here (if working with git etc.)


### dim_locations.sql

```sql
WITH taxi_zone_lookup AS (
    SELECT * FROM {{ ref('taxi_zone_lookup') }}
),
renamed AS (
    SELECT
        locationid AS location_id,
        borough,
        zone,
        service_zone
    FROM taxi_zone_lookup
)

SELECT * FROM taxi_zone_lookup
```

### dim_vendors.sql

Vendors are hardcoded here -> can be made more adaptive / general with macro

```sql
WITH trips_unioned AS (
    SELECT * FROM {{ ref("int_trips_unioned") }}
),
vendors AS (
    SELECT
        DISTINCT(vendor_id),
        CASE 
            WHEN vendor_id = 1 THEN 'Creative Mobile Te3chnologies, LLC'
            WHEN vendor_id = 2 THEN 'VeriFone Inc.'
            WHEN vendor_id = 4 THEN 'Unknown Vendor'
        END AS vendor_name
    FROM
        trips_unioned
)

SELECT * FROM vendors
```

Create macro `get_vendor_names.sql` in `macros` folder:
```sql
{% macro get_vendor_names(vendor_id) -%}
CASE
    WHEN {{ vendor_id }} = 1 THEN 'Creative Mobile Te3chnologies, LLC'
    WHEN {{ vendor_id }} = 2 THEN 'VeriFone Inc.'
    WHEN {{ vendor_id }} = 4 THEN 'Unknown Vendor'
END
{%- endmacro %}
```

Use macro in `dim_vendors.sql`:
```sql
WITH trips_unioned AS (
    SELECT * FROM {{ ref("int_trips_unioned") }}
),
vendors AS (
    SELECT
        DISTINCT(vendor_id),
        {{ get_vendor_names('vendor_id') }} AS vendor_name
    FROM
        trips_unioned
)

SELECT * FROM vendors
```

Now this macro can be used everywhere and only the macro has to be changed for adapting to changes.
