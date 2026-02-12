SELECT
    -- identifiers
    CAST(vendorid AS INT) AS vendor_id,
    CAST(ratecodeid AS INT) AS rate_code_id,
    CAST(pulocationid AS INT) AS pickup_location_id,
    CAST(dolocationid AS INT) AS dropoff_location_id,

    -- timestamps
    CAST(lpep_pickup_datetime AS TIMESTAMP) AS pickup_datetime,
    CAST(lpep_dropoff_datetime AS TIMESTAMP) AS dropoff_datetime,

    -- trip info
    store_and_fwd_flag,
    CAST(passenger_count AS INT),
    CAST(trip_distance AS FLOAT),
    CAST(trip_type AS INT),

    -- payment info
    CAST(fare_amount AS NUMERIC),
    CAST(extra AS NUMERIC),
    CAST(mta_tax AS NUMERIC),
    CAST(tip_amount AS NUMERIC),
    CAST(tolls_amount AS NUMERIC),
    CAST(improvement_surcharge AS NUMERIC),
    CAST(total_amount AS NUMERIC),
    CAST(payment_type AS INT)
FROM
    {{ source('raw_data', 'green_tripdata') }}
WHERE
    vendor_id IS NOT NULL;