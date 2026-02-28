# Module 5 Homework: Data Platforms with Bruin

In this homework, we'll use Bruin to build a complete data pipeline, from ingestion to reporting.

## Setup

1. Install Bruin CLI: `curl -LsSf https://getbruin.com/install/cli | sh`
2. Initialize the zoomcamp template: `bruin init zoomcamp my-pipeline`
3. Configure your `.bruin.yml` with a DuckDB connection
4. Follow the tutorial in the [main module README](../../../05-data-platforms/)

After completing the setup, you should have a working NYC taxi data pipeline.

---

### Question 1. Bruin Pipeline Structure

In a Bruin project, what are the required files/directories?

- `bruin.yml` and `assets/`
- `.bruin.yml` and `pipeline.yml` (assets canWh be anywhere)
- `.bruin.yml` and `pipeline/` with `pipeline.yml` and `assets/`
- `pipeline.yml` and `assets/` only


#### Answer 1

> - `.bruin.yml` and `pipeline/` with `pipeline.yml` and `assets/`



### Question 2. Materialization Strategies

You're building a pipeline that processes NYC taxi data organized by month based on `pickup_datetime`. Which incremental strategy is best for processing a specific interval period by deleting and inserting data for that time period?

- `append` - always add new rows
- `replace` - truncate and rebuild entirely
- `time_interval` - incremental based on a time column
- `view` - create a virtual table only

#### Answer 2

> - `time_interval` - incremental based on a time column



### Question 3. Pipeline Variables

You have the following variable defined in `pipeline.yml`:

```yaml
variables:
  taxi_types:
    type: array
    items:
      type: string
    default: ["yellow", "green"]
```

How do you override this when running the pipeline to only process yellow taxis?

- `bruin run --taxi-types yellow`
- `bruin run --var taxi_types=yellow`
- `bruin run --var 'taxi_types=["yellow"]'`
- `bruin run --set taxi_types=["yellow"]`

#### Answer 3

> - `bruin run --var 'taxi_types=["yellow"]'`



### Question 4. Running with Dependencies

You've modified the `ingestion/trips.py` asset and want to run it plus all downstream assets. Which command should you use?

- `bruin run ingestion.trips --all`
- `bruin run ingestion/trips.py --downstream`
- `bruin run pipeline/trips.py --recursive`
- `bruin run --select ingestion.trips+`

#### Answer 4

`bruin run ingestion/trips.py --downstream`

Source: https://getbruin.com/docs/bruin/commands/run#flags


### Question 5. Quality Checks

You want to ensure the `pickup_datetime` column in your trips table never has NULL values. Which quality check should you add to your asset definition?

- `name: unique`
- `name: not_null`
- `name: positive`
- `name: accepted_values, value: [not_null]`

#### Answer 5

- `name: not_null`

Source: https://getbruin.com/docs/bruin/quality/available_checks#not-null


### Question 6. Lineage and Dependencies

After building your pipeline, you want to visualize the dependency graph between assets. Which Bruin command should you use?

- `bruin graph`
- `bruin dependencies`
- `bruin lineage`
- `bruin show`

#### Answer 6

- `bruin lineage`

Source: https://getbruin.com/docs/bruin/commands/lineage


### Question 7. First-Time Run

You're running a Bruin pipeline for the first time on a new DuckDB database. What flag should you use to ensure tables are created from scratch?

- `--create`
- `--init`
- `--full-refresh`
- `--truncate`


#### Answer 7

- `--full-refresh`
