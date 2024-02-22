{{
    config(
        materialized='table'
    )
}}

with counter as (
    select *, -- count(*) as trip_count
    from {{ ref('fact_fhv_trips') }}
)

select * from counter