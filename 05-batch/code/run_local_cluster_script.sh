#!/usr/bin/bash

URL="spark://hp-computer:7077"

spark-submit \
    --master="${URL}" \
    local_cluster_spark.py \
        --input_green=../data/data/raw/green/2021/*/ \
        --input_yellow=../data/data/raw/yellow/2021/*/ \
        --output=../data/data/report-2021