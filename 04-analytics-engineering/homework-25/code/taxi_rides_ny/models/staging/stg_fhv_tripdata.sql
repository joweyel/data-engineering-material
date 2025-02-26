{{
    config(materialized='view')
}}

with tripdata as
(
    select *,
        row_number() over(partition by dispatching_base_num, pickup_datetime) as rn
    from {{ source('staging', 'fhv_tripdata') }}
    where dispatching_base_num is not null
)
select
    -- identifiers
    {{ dbt_utils.generate_surrogate_key(['dispatching_base_num', 'pickup_datetime']) }} as tripid,
    {{ dbt.safe_cast("dispatching_base_num", api.Column.translate_type("string")) }} as dispatchid,
    {{ dbt.safe_cast("Affiliated_base_number", api.Column.translate_type("string")) }} as affiliatedid,
    {{ dbt.safe_cast("PUlocationID", api.Column.translate_type("integer")) }} as pickup_locationid,
    {{ dbt.safe_cast("DOlocationID", api.Column.translate_type("integer")) }} as dropoff_locationid,

    -- timestamps
    cast(pickup_datetime as timestamp) as pickup_datetime,
    cast(dropOff_datetime as timestamp) as dropoff_datetime,

    -- other
    SR_Flag as sr_flag

FROM
    tripdata

-- dbt build --select <model.sql> --vars '{'is_test_run: false}'
{% if var('is_test_run', default=true) %}

  limit 100

{% endif %}