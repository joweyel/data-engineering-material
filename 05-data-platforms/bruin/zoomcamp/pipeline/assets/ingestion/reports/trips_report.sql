/* @bruin

# Docs:
# - SQL assets: https://getbruin.com/docs/bruin/assets/sql
# - Materialization: https://getbruin.com/docs/bruin/assets/materialization
# - Quality checks: https://getbruin.com/docs/bruin/quality/available_checks

name: reports.trips_report
type: duckdb.sql

# Declare dependency on the staging asset this report reads from.
depends:
  - staging.trips

# Use the same incremental_key as staging for consistency.
# time_interval deletes the window then re-inserts the aggregation.
materialization:
  type: table

columns:
  - name: trip_date
    type: date
    description: "Date of the trip (truncated from pickup_datetime)"
    primary_key: true
    checks:
      - name: not_null
  - name: taxi_type
    type: string
    description: "Taxi type (yellow or green)"
    primary_key: true
    checks:
      - name: not_null
  - name: payment_type_name
    type: string
    description: "Human-readable payment type"
    primary_key: true
    checks:
      - name: not_null
  - name: trip_count
    type: integer
    description: "Number of trips"
    checks:
      - name: non_negative
  - name: total_passengers
    type: integer
    description: "Total passenger count"
    checks:
      - name: non_negative
  - name: total_trip_distance
    type: float
    description: "Total distance across all trips in miles"
    checks:
      - name: non_negative
  - name: total_fare_amount
    type: float
    description: "Sum of base fares"
    checks:
      - name: non_negative
  - name: total_tip_amount
    type: float
    description: "Sum of tips"
    checks:
      - name: non_negative
  - name: total_amount_sum
    type: float
    description: "Sum of total amounts"
    checks:
      - name: non_negative
  - name: avg_passenger_count
    type: float
    description: "Average passenger count per trip"
    checks:
      - name: non_negative
  - name: avg_trip_distance
    type: float
    description: "Average trip distance in miles"
    checks:
      - name: non_negative
  - name: avg_fare_amount
    type: float
    description: "Average base fare"
    checks:
      - name: non_negative

@bruin */

-- Purpose of reports:
-- - Aggregate staging data for dashboards and analytics
-- - GROUP BY trip_date, taxi_type, payment_type_name
-- - Filter using {{ start_datetime }} / {{ end_datetime }} for incremental runs
-- - Use the same incremental_key (pickup_datetime) as staging for consistency

SELECT
    CAST(pickup_datetime AS DATE) AS trip_date,
    taxi_type,
    payment_type_name,

    -- Count metrics
    COUNT(*) AS trip_count,
    COALESCE(SUM(passenger_count), 0) AS total_passengers,

    -- Distance metrics
    COALESCE(SUM(trip_distance), 0)                 AS total_trip_distance,
    COALESCE(AVG(trip_distance), 0)                 AS avg_trip_distance,

    -- Revenue metrics
    COALESCE(SUM(fare_amount), 0)                   AS total_fare_amount,
    COALESCE(SUM(tip_amount), 0)                    AS total_tip_amount,
    COALESCE(SUM(total_amount), 0)                  AS total_amount_sum,

    -- Average metrics
    COALESCE(AVG(passenger_count), 0)               AS avg_passenger_count,
    COALESCE(AVG(trip_distance), 0)                 AS avg_trip_distance,
    COALESCE(AVG(fare_amount), 0)                   AS avg_fare_amount

FROM staging.trips
WHERE pickup_datetime >= '{{ start_datetime }}'
  AND pickup_datetime <  '{{ end_datetime }}'
GROUP BY
    CAST(pickup_datetime AS DATE),
    taxi_type,
    payment_type_name
