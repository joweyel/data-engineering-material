Thanks to amazing foresight last year I was able to get my hands on RAM that was able to handle this locally.

## Question 1. dbt Lineage and Execution

Given a dbt project with the following structure:

```
models/
├── staging/
│   ├── stg_green_tripdata.sql
│   └── stg_yellow_tripdata.sql
└── intermediate/
    └── int_trips_unioned.sql (depends on stg_green_tripdata & stg_yellow_tripdata)
```

If you run `dbt run --select int_trips_unioned`, what models will be built?

- `stg_green_tripdata`, `stg_yellow_tripdata`, and `int_trips_unioned` (upstream dependencies)
- Any model with upstream and downstream dependencies to `int_trips_unioned`
- `int_trips_unioned` only
- `int_trips_unioned`, `int_trips`, and `fct_trips` (downstream dependencies)

### Answer 1

> `int_trips_unioned` only


## Question 2. dbt Tests

You've configured a generic test like this in your `schema.yml`:

```yaml
columns:
  - name: payment_type
    data_tests:
      - accepted_values:
          arguments:
            values: [1, 2, 3, 4, 5]
            quote: false
```

Your model `fct_trips` has been running successfully for months. A new value `6` now appears in the source data.

What happens when you run `dbt test --select fct_trips`?

- dbt will skip the test because the model didn't change
- dbt will fail the test, returning a non-zero exit code
- dbt will pass the test with a warning about the new value
- dbt will update the configuration to include the new value


### Answer 2

> dbt will fail the test, returning a non-zero exit code


## Question 3. Counting Records in `fct_monthly_zone_revenue`

After running your dbt project, query the `fct_monthly_zone_revenue` model.

What is the count of records in the `fct_monthly_zone_revenue` model?

- 12,998
- 14,120
- 12,184
- 15,421

### Answer 3

```bash
duckdb taxi_rides_ny.duckdb -c "SELECT COUNT(*) FROM prod.fct_monthly_zone_revenue;" 
```

```
┌──────────────┐
│ count_star() │
│    int64     │
├──────────────┤
│    12184     │
└──────────────┘
```

> `12,184`


## Question 4. Best Performing Zone for Green Taxis (2020)

Using the `fct_monthly_zone_revenue` table, find the pickup zone with the **highest total revenue** (`revenue_monthly_total_amount`) for **Green** taxi trips in 2020.

Which zone had the highest revenue?

- East Harlem North
- Morningside Heights
- East Harlem South
- Washington Heights South


### Answer 4

Query:
```sql
SELECT
  SUM(revenue_monthly_total_amount) AS total_amount,
  pickup_zone
FROM
  prod.fct_monthly_zone_revenue
WHERE
  service_type = 'Green' AND
  EXTRACT(YEAR FROM revenue_month) = 2020
GROUP BY
  pickup_zone
ORDER BY
  total_amount DESC
LIMIT
  1
```

Result
```
┌───────────────┬───────────────────┐
│ total_amount  │    pickup_zone    │
│ decimal(38,3) │      varchar      │
├───────────────┼───────────────────┤
│  1817374.950  │ East Harlem North │
└───────────────┴───────────────────┘
```

> `East Harlem North`



## Question 5. Green Taxi Trip Counts (October 2019)

Using the `fct_monthly_zone_revenue` table, what is the **total number of trips** (`total_monthly_trips`) for Green taxis in October 2019?

- 500,234
- 350,891
- 384,624
- 421,509


### Answer 5

Query:
```sql
SELECT
  SUM(total_monthly_trips)
FROM
  prod.fct_monthly_zone_revenue
WHERE
  service_type = 'Green' AND
  EXTRACT(YEAR FROM revenue_month) = 2019 AND 
  EXTRACT(MONTH FROM revenue_month) = 10
```

Result:

```
┌──────────────────────────┐
│ sum(total_monthly_trips) │
│          int128          │
├──────────────────────────┤
│          384624          │
└──────────────────────────┘
```


## Question 6. Build a Staging Model for FHV Data

Create a staging model for the **For-Hire Vehicle (FHV)** trip data for 2019.

1. Load the [FHV trip data for 2019](https://github.com/DataTalksClub/nyc-tlc-data/releases/tag/fhv) into your data warehouse
2. Create a staging model `stg_fhv_tripdata` with these requirements:
   - Filter out records where `dispatching_base_num IS NULL`
   - Rename fields to match your project's naming conventions (e.g., `PUlocationID` → `pickup_location_id`)

What is the count of records in `stg_fhv_tripdata`?

- 42,084,899
- 43,244,693
- 22,998,722
- 44,112,187


### Answer 6

Run the following `fhv` ingestion script ([ingest_fhv.py](./taxi_rides_ny/ingest_fhv.py)) when working locally:
```bash
python3 ingest_fhv.py
```

Updating the sources [taxi_rides_ny/models/staging/sources.yml](taxi_rides_ny/models/staging/sources.yml):

<details>

<summary><b>sources.yml</b></summary>

```yaml
sources:
  - name: raw
    description: Raw taxi trip data from NYC TLC
    database: |
      {%- if target.type == 'bigquery' -%}
        {{ env_var('GCP_PROJECT_ID', 'please-add-your-gcp-project-id-here') }}
      {%- else -%}
        taxi_rides_ny
      {%- endif -%}
    schema: |
      {%- if target.type == 'bigquery' -%}
        nytaxi
      {%- else -%}
        prod
      {%- endif -%}
    freshness:
      warn_after: {count: 24, period: hour}
      error_after: {count: 48, period: hour}
    tables:
      - name: green_tripdata
      ...
      - name: green_tripdata
      ...
      - name: fhv_tripdata
        description: Raw For-Hire Vehicle trip records
        loaded_at_field: pickup_datetime
        columns:
          - name: dispatching_base_num
            description: TLC base company code of the base that dispatched the trip
          - name: pickup_datetime
            description: Date and time when the passenger was picked up
          - name: dropOff_datetime
            description: Date and time when the passenger was dropped off
          - name: PUlocationID
            description: TLC Taxi Zone where the passenger was picked up
          - name: DOlocationID
            description: TLC Taxi Zone where the passenger was dropped off
          - name: SR_Flag
            description: Shared ride flag (indicates if trip was part of a shared ride)
          - name: Affiliated_base_number
            description: Base number affiliated with the dispatching base
```

</details>
<br>

Updating [schema.yml](./taxi_rides_ny/models/staging/schema.yml#L96) of staging models:

<details>

<summary><b>schema.yml</b></summary>

```yaml
models:
  - name: stg_green_tripdata
    ... 

  - name: stg_yellow_tripdata
    ...

  - name: stg_fhv_tripdata
    description: >
      Staging model for For-Hire Vehicle (FHV) trip data. This model standardizes column names
      and data types from the raw fhv_tripdata source, filtering out records with null
      dispatching_base_num and generating a surrogate key for each trip.
    columns:
      - name: trip_id
        description: Surrogate key generated from dispatching_base_num and pickup_datetime
        data_tests:
          - unique
          - not_null
      - name: dispatching_base_num
        description: TLC base company code of the base that dispatched the trip
        data_tests:
          - not_null
      - name: pickup_location_id
        description: TLC Taxi Zone where the passenger was picked up
      - name: dropoff_location_id
        description: TLC Taxi Zone where the passenger was dropped off
      - name: pickup_datetime
        description: Date and time when the passenger was picked up
        data_tests:
          - not_null
      - name: dropoff_datetime
        description: Date and time when the passenger was dropped off
      - name: sr_flag
        description: Shared ride flag (indicates if trip was part of a shared ride)
      - name: affiliated_base_number
        description: Base number affiliated with the dispatching base
```
</details>
<br>

Create dbt staging model for fhv tripdata:
```bash
dbt run --select stg_fhv_tripdata --target prod
```

Query:
```sql
SELECT 
    COUNT(*) 
FROM 
    prod.stg_fhv_tripdata;
```

Get the data from duckdb:
```bash
duckdb taxi_rides_ny.duckdb -c "SELECT COUNT(*) FROM prod.stg_fhv_tripdata;"
```

Result:
```
┌─────────────────┐
│  count_star()   │
│      int64      │
├─────────────────┤
│    43244693     │
│ (43.24 million) │
└─────────────────┘
```

> `43,244,693`