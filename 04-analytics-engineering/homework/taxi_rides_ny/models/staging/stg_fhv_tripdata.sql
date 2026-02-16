{{ 
    config(materialized='view') 
}}

WITH source AS (
    SELECT * FROM {{ source('raw', 'fhv_tripdata') }}
),


renamed AS (
    SELECT
        -- identifiers
        {{ dbt_utils.generate_surrogate_key(['dispatching_base_num', 'pickup_datetime']) }} AS trip_id,
        {{ dbt.safe_cast('dispatching_base_num', 'string') }} as dispatching_base_num,
        CAST(PUlocationID AS INTEGER) AS pickup_location_id,
        CAST(DOlocationID AS INTEGER) AS dropoff_location_id,

        -- timestamps 
        CAST(pickup_datetime AS TIMESTAMP) AS pickup_datetime,
        CAST(dropOff_datetime AS TIMESTAMP) AS dropoff_datetime,

        -- trip info
        {{ dbt.safe_cast('SR_Flag', 'integer') }} AS sr_flag,
        {{ dbt.safe_cast('Affiliated_base_number', 'string') }} as affiliated_base_number
    FROM
        source
    WHERE
        dispatching_base_num IS NOT NULL
)

SELECT * FROM renamed

{% if target.name == 'dev' %}
    WHERE
        pickup_datetime >= '2019-01-01' AND 
        pickup_datetime < '2019-02-01'
{% endif %}