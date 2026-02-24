/* @bruin

# Docs:
# - Materialization: https://getbruin.com/docs/bruin/assets/materialization
# - Quality checks (built-ins): https://getbruin.com/docs/bruin/quality/available_checks
# - Custom checks: https://getbruin.com/docs/bruin/quality/custom

name: staging.trips
type: duckdb.sql

#  Declare dependencies so `bruin run ... --downstream` and lineage work.
depends:
  - ingestion.trips
  - ingestion.payment_lookup

# time_interval: deletes rows where incremental_key falls within the run window,
# then inserts the result of your query. Use time_granularity: timestamp when
# the incremental_key is a TIMESTAMP column.
materialization:
  type: table

columns:
  - name: pickup_datetime
    type: timestamp
    description: "When the trip started"
    primary_key: true
    checks:
      - name: not_null
  - name: dropoff_datetime
    type: timestamp
    description: "When the trip ended"
    primary_key: true
    checks:
      - name: not_null
  - name: pickup_location_id
    type: integer
    description: "TLC Taxi Zone pickup location ID"
    primary_key: true
    checks:
      - name: not_null
  - name: dropoff_location_id
    type: integer
    description: "TLC Taxi Zone dropoff location ID"
    primary_key: true
    checks:
      - name: not_null
  - name: fare_amount
    type: float
    description: "Base fare in USD"
    primary_key: true
    checks:
      - name: not_null
  - name: payment_type_name
    type: string
    description: "Human-readable payment type from lookup"
    checks:
      - name: not_null
  - name: taxi_type
    type: string
    description: "Taxi type (yellow or green)"
    checks:
      - name: not_null
      - name: accepted_values
        value: ["yellow", "green"]

# Add one custom check that validates a staging invariant (uniqueness, ranges, etc.)
custom_checks:
  - name: row_count_positive
    description: Ensures table is not empty (returns 1 if true)
    query: SELECT COUNT(*) > 0 FROM staging.trips
    value: 1

@bruin */

-- Write the staging SELECT query.
--
-- Purpose of staging:
-- - Clean and normalize schema from ingestion
-- - Deduplicate records (important if ingestion uses append strategy)
-- - Enrich with lookup tables (JOINs)
-- - Filter invalid rows (null PKs, negative values, etc.)
--
-- Normalization:
--   1. Yellow taxis use tpep_pickup_datetime / tpep_dropoff_datetime
--   2. Green taxis use lpep_pickup_datetime / lpep_dropoff_datetime
--   → COALESCE both into pickup_datetime / dropoff_datetime
--
-- Deduplication (composite key):
--   1. Partition by (pickup_datetime, dropoff_datetime, pickup_location_id, dropoff_location_id, fare_amount)
--   2. Keep the latest row per partition using ROW_NUMBER() ordered by extracted_at DESC
--
-- Why filter by {{ start_datetime }} / {{ end_datetime }}?
-- When using `time_interval` strategy, Bruin:
--   1. DELETES rows where `incremental_key` falls within the run's time window
--   2. INSERTS the result of your query
-- Therefore, your query MUST filter to the same time window so only that subset is inserted.
-- If you don't filter, you'll insert ALL data but only delete the window's data = duplicates.

WITH normalized AS (
    SELECT
        -- Pickup / dropoff datetime
        tpep_pickup_datetime AS pickup_datetime,
        tpep_dropoff_datetime AS dropoff_datetime,
        
        -- Location IDs
        pu_location_id AS pickup_location_id,
        do_location_id AS dropoff_location_id,

        -- Other
        passenger_count,
        trip_distance,
        payment_type,
        fare_amount,
        extra,
        mta_tax,
        tip_amount,
        tolls_amount,
        improvement_surcharge,
        total_amount,
        congestion_surcharge,
        taxi_type,
        extracted_at
    FROM 
        ingestion.trips
    WHERE 
        1=1 AND
        -- Filter out invalud records
        tpep_pickup_datetime IS NOT NULL AND
        fare_amount >= 0 AND
        total_amount >= 0
),

deduplicated AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                pickup_datetime,
                dropoff_datetime,
                pickup_location_id,
                dropoff_location_id,
                fare_amount
            ORDER BY
              extracted_at DESC
        ) AS row_num
    FROM
        normalized
)

SELECT
    d.pickup_datetime,
    d.dropoff_datetime,
    d.pickup_location_id,
    d.dropoff_location_id,
    d.passenger_count,
    d.trip_distance,
    d.payment_type,
    COALESCE(p.payment_type_name, 'unknown') AS payment_type_name,
    d.fare_amount,
    d.extra,
    d.mta_tax,
    d.tip_amount,
    d.tolls_amount,
    d.improvement_surcharge,
    d.total_amount,
    d.congestion_surcharge,
    d.taxi_type,
    d.extracted_at
FROM 
    deduplicated AS d
LEFT JOIN ingestion.payment_lookup AS p
    ON d.payment_type = p.payment_type_id
