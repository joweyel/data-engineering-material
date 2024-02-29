#!/usr/bin/bash

gcloud dataproc jobs submit pyspark \
    --cluster=cluster-e87b \
    --region=europe-west3 \
    --jars=gs://spark-lib/bigquery/spark-bigquery-latest_2.12.jar \
    gs://dtc_data_lake_de-zoomcap-nytaxi/code/bigquery_spark.py \
    -- \
        --input_green=gs://dtc_data_lake_de-zoomcap-nytaxi/pq/raw/green/2020/*/ \
        --input_yellow=gs://dtc_data_lake_de-zoomcap-nytaxi/pq/raw/yellow/2020/*/ \
        --output=trips_data_all.reports-2020
