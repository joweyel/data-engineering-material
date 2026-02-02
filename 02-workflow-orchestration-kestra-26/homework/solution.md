# Module 2 Homework Solution

> In case you don't get one option exactly, select the closest one 

For the homework, we'll be working with the _green_ taxi dataset located here:

`https://github.com/DataTalksClub/nyc-tlc-data/releases/tag/green/download`

To get a `wget`-able link, use this prefix (note that the link itself gives 404):

`https://github.com/DataTalksClub/nyc-tlc-data/releases/download/green/`

## Assignment

So far in the course, we processed data for the year 2019 and 2020. Your task is to extend the existing flows to include data for the year 2021.


The flow used for this is [09_gcp_taxi_scheduled](../flows/08_gcp_taxi.yaml)

### Question 1

Within the execution for `Yellow` Taxi data for the year `2020` and month `12`: what is the uncompressed file size (i.e. the output file `yellow_tripdata_2020-12.csv` of the `extract` task)?
- 128.3 MiB
- 134.5 MiB
- 364.7 MiB
- 692.6 MiB

**Answer**: 

- 128.3 MiB


---

### Question 2

What is the rendered value of the variable `file` when the inputs `taxi` is set to `green`, `year` is set to `2020`, and `month` is set to `04` during execution?
- `{{inputs.taxi}}_tripdata_{{inputs.year}}-{{inputs.month}}.csv` 
- `green_tripdata_2020-04.csv`
- `green_tripdata_04_2020.csv`
- `green_tripdata_2020.csv`

**Answer**:

```yaml
file: "{{inputs.taxi}}_tripdata_{{trigger.date | date('yyyy-MM')}}.csv"
#           green                    2020-04
# The result is: green_tripdata_2020-04.csv
```

![q2](images/q2.png)


---


### Question 3

How many rows are there for the `Yellow` Taxi data for all CSV files in the year 2020?
- 13,537.299
- 24,648,499
- 18,324,219
- 29,430,127

**Answer**:

```sql
SELECT 
    COUNT(1) 
FROM 
    `kestra-workspace.zoomcamp.yellow_tripdata` 
WHERE 
    EXTRACT(YEAR FROM tpep_pickup_datetime) = 2020;
```

- **`24,648,499`**


---


### Question 4

How many rows are there for the `Green` Taxi data for all CSV files in the year 2020?
- 5,327,301
- 936,199
- 1,734,051
- 1,342,034

**Answer**:

```sql
SELECT 
    COUNT(1)
FROM 
    `kestra-workspace.zoomcamp.green_tripdata` 
WHERE 
    EXTRACT(YEAR FROM lpep_pickup_datetime) = 2020;
```

- **`1,734,051`**


---


### Question 5

How many rows are there for the `Yellow` Taxi data for the March 2021 CSV file?
- 1,428,092
- 706,911
- 1,925,152
- 2,561,031


**Answer**:

```sql
SELECT 
    COUNT(1) 
FROM 
    `kestra-workspace.zoomcamp.yellow_tripdata` 
WHERE 
    EXTRACT(MONTH FROM tpep_pickup_datetime) = 3 AND 
    EXTRACT(YEAR FROM tpep_pickup_datetime) = 2021;
```

- **`1,925,152`**


---


### Question 6

How would you configure the timezone to New York in a Schedule trigger?
- Add a `timezone` property set to `EST` in the `Schedule` trigger configuration
- Add a `timezone` property set to `America/New_York` in the `Schedule` trigger configuration
- Add a `timezone` property set to `UTC-5` in the `Schedule` trigger configuration
- Add a `location` property set to `New_York` in the `Schedule` trigger configuration


**Answer**:

Add a `timezone` property set to `America/New_York` in the `Schedule` trigger configuration

```yaml
id: 09_gcp_taxi_scheduled
namespace: zoomcamp
...
# Example:
triggers:
  - id: green_schedule
    type: io.kestra.plugin.core.trigger.Schedule
    cron: "0 9 1 * *"
    timezone: America/New_York
    inputs:
      taxi: green

  - id: yellow_schedule
    type: io.kestra.plugin.core.trigger.Schedule
    cron: "0 10 1 * *"
    timezone: America/New_York
    inputs:
      taxi: yellow
```