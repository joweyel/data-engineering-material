{{
    config(materialized='table')
}}

WITH quarterly_revenue AS (
    SELECT
        service_type,
        EXTRACT(YEAR FROM pickup_datetime) AS year,
        EXTRACT(QUARTER FROM pickup_datetime) AS quarter,
        SUM(total_amount) AS quarterly_revenue
    FROM {{ ref('fact_trips') }}
),
yoy_growth AS (
    -- TODO
)