# Module 5 - Bruin NYC Taxi Tutorial Notes

## 01 - Bruin Tutorial | NYC Taxi | Part 1

Introduction to the Bruin Data Platform. Bruin is an end-to-end data platform that consolidates ingestion, transformation, orchestration, data quality checks, metadata management, and lineage into a single tool - replacing the need for five or more separate tools.

**Learning goals covered:**
- Bruin project structure
- What a pipeline and assets are
- Pipeline configuration
- Materialization strategies
- Bruin lineage and asset dependencies
- Metadata (automatic and manual)
- Parameterizing pipelines with custom variables

**Modern data stack overview:**
- ETL/ELT: extract data from third-party sources or databases → load into data warehouse/lake → transform, clean, and create reports
- An orchestrator controls when and how each step runs - telling different scripts and services when to run, how to communicate with each other
- Data governance includes quality checks (accuracy, completeness, consistency) before data reaches consumers
- Bruin brings all of this together into a single project: your code logic, configurations, dependencies, and quality checks all in one place - without needing to be a DevOps person, a data infrastructure person, and a data architect just to build a pipeline

## 02 - Bruin Tutorial | NYC Taxi | Part 2

Covers installing Bruin, creating the first project from a template, and walking through core concepts with a hands-on demo using chess.com data.

**Installation:**

```bash
curl -LsSf https://getbruin.com/install/cli | sh
```

The speaker referred to a `curl` command as the recommended install method. After installation, also install the Bruin extension in VS Code or Cursor to get the Bruin Render panel.

**Bruin MCP:**
- Model Context Protocol allows AI agents (e.g. Cursor) to communicate with Bruin
- Add via IDE settings → Tools → MCP → New MCP server, paste the Bruin MCP config
- The project must be Git-initialized - `bruin init` handles this automatically
- If the MCP shows as unavailable, close and reopen the IDE

**Project initialization (`bruin init`):**
- Presents a list of templates; the demo uses the `default` template
- Creates a subfolder with the first pipeline, a `.gitignore`, and a `.bruin.yml` file
- `.bruin.yml` is local-only, auto-added to `.gitignore` - stores environment definitions and connection secrets, **never commit this file**
- Inside `.bruin.yml`: define environments (default, production, sandbox, staging…) and under each, define connections

**Pipeline YAML:**
- Defines pipeline name, schedule, and default connection
- `start_date` sets the earliest date used when doing a full refresh
- `catch_up` not needed for this tutorial

**Key concepts:**
- **Environments:** named sets of connections (e.g. `default`, `production`)
- **Connections:** credentials per environment - e.g. DuckDB for local warehouse, chess.com as a built-in data source
- **Assets:** scripts or queries in the `assets/` folder - can extract, transform, or push data; can be organized in subfolders
- **Intervals:** `start_date` / `end_date` injected as variables into assets for incremental ingestion

**Asset types demonstrated:**
- **Python asset** - just prints "hello"; shows the basic structure: give it a name, run it from the panel
- **Ingester YAML asset** (chess.com → DuckDB):
  - Defines `type: ingest`, source connection, destination connection, and table name
  - Bruin has many built-in ingest sources (Redshift, MySQL, MotherDuck, BigQuery, etc.) - see documentation
  - `start_date` / `end_date` are automatically passed to built-in ingesters; demonstrated ingesting all of 2025
- **SQL asset** - basic `COUNT(*)` aggregation; depends on the ingester asset, so it triggers automatically after ingestion; materialization `table` creates the table from the query

## 03 - Bruin Tutorial | NYC Taxi | Part 3

Building a real end-to-end pipeline using New York City Taxi data with a three-layer architecture on DuckDB.

**Architecture:**
- **Ingestion layer:** extract raw data from NYC Taxi API → store in DuckDB in raw format
- **Staging layer:** clean, deduplicate, join with lookup tables, cast data types
- **Report layer:** aggregate and calculate final metrics

All assets across the three layers have dependencies, which creates the data lineage Bruin uses for orchestration.

**Project setup:**

```bash
bruin init zoomcamp
```

Creates the pipeline folder, a README with full instructions, and a three-tier folder structure with TODOs to complete. The file structure matches the three layers: `ingestion/`, `staging/`, `reports/` under `assets/`.

**Pipeline configuration (`pipeline.yml`):**
- Name: `nyc_taxi`, schedule: `daily`, start date: `2022-01-01`, default connection: `duckdb_default`
- Custom variable: `taxi_types` (array type, default `["yellow"]`) - allows overriding at runtime to run for yellow only, green only, or both

**Ingestion layer assets:**

- **Python asset** (`ingestion.trips`):
  - Dataset name set explicitly so data goes into a named schema rather than the default one
  - Type: `python`; materialization: `table` with `append` strategy - each run only inserts new data
  - Must define a `materialize()` function that returns a DataFrame; Bruin handles writing it to the DB
  - Reads `BRUIN_START_DATE` / `BRUIN_END_DATE` env vars; generates a list of months to fetch
  - Filters by `taxi_types` custom variable (yellow and/or green)
  - Columns can be defined manually for full metadata, or auto-generated with `fill from DB`
  - `requirements.txt` per pipeline - Bruin installs dependencies locally, isolated per pipeline

- **Seed asset** (payment lookup table from local CSV):
  - Reads a local CSV file into DuckDB
  - Can also point to a CSV at a URL
  - Built-in quality checks (`not_null`, `unique`) defined on columns - run automatically after ingestion

**Staging layer (`staging.trips`):**
- DuckDB SQL asset (`.db.sql`)
- Dependencies set to both ingestion assets → triggers automatically once they complete
- Materialization: `table` (kept simple - deletes and recreates the table each run)
- Custom quality check: a SQL query that returns 1 if row count > 0; must match the expected value to pass
- SQL written by Cursor: casts pickup/dropoff datetimes, deduplicates, joins with payment lookup table

**Report layer:**
- DuckDB SQL asset depending on staging
- Materialization: `table` - Bruin compiles the full transaction (drop if exists, create, insert) automatically
- Simple aggregation by trip date, taxi type, and payment type
- Columns and quality checks defined in the asset header

**Lineage:** visible in the Bruin panel's lineage tab after opening `pipeline.yml` - shows all assets and dependency connections

**Running the full pipeline:**
After all assets are set up, create a run from the panel with a selected date interval. All assets execute in dependency order and the lineage view shows them completing in sequence.

## 04 - Bruin Cloud Onboarding

Introduction to Bruin Cloud - a fully managed infrastructure platform powered by the same open-source CLI used locally.

**Features:**
- Ingestion, transformations, quality checks, lineage, metadata, and data governance all in one place
- AI-powered features: auto-generate metadata; chat with an AI agent to analyze data, ask about pipelines, or explore metadata

**Onboarding steps:**
1. Register with name, email, and password → verify via email link
2. Create a new organization or join an existing team
3. Connect GitHub: directly (easier, allows dropdown repo selection) or via a Personal Access Token + manual repo URL
4. Create workspace
5. Add connections - use the same connection names as in your local `.bruin.yml` (MotherDuck, BigQuery, Redshift, etc.)
   - Connections are validated and tested automatically in the background
   - Fully secured - see documentation for details on secret management

**Running pipelines in Bruin Cloud:**
- Navigate to the Pipelines page → find your pipeline from the connected repo
- Bruin validates every asset and checks lineage before the pipeline can be enabled (takes a moment)
- Enable the pipeline → it automatically creates a run for the last interval based on the configured schedule
- All asset statuses, quality check results, and logs are visible in the dashboard

**Community:** Slack community for questions and feature requests; GitHub issues for bug reports

## 05 - Bruin Tutorial | NYC Taxi | Part 4

Using Bruin MCP with an AI agent (Cursor) to build the entire NYC Taxi pipeline end-to-end from a single prompt.

**What is Bruin MCP:**
- Model Context Protocol - a way for AI agents to add additional context when being prompted
- Lets the agent communicate with Bruin: query its documentation, run commands on your behalf, go through your code, troubleshoot, run queries, and analyze data
- Integrates with Cursor, Claude, and other agents - see documentation for each

**Installing MCP in Cursor:**

Settings → Tools → MCP → New MCP server, paste the config from the Bruin documentation:

```json
{
  "mcpServers": {
    "bruin": {
      "command": "bruin",
      "args": ["mcp"]
    }
  }
}
```

Restart the IDE if it shows as unavailable or shows an error.

**Building the pipeline with a single prompt:**
- The template README includes an example prompt to give to the agent that builds the entire pipeline end-to-end
- The agent creates all assets, runs the pipeline for one month, validates data with built-in quality checks, and runs additional ad-hoc queries to verify correctness
- One small error was made (an extra pipeline folder created) but easily cleaned up

**What the AI agent generated - ingestion asset (Python):**
- Configured the asset header correctly: name, type, image, materialization as `table` with `append` strategy, and column metadata
- `materialize()` function: reads `BRUIN_START_DATE` / `BRUIN_END_DATE` and `taxi_types` from env vars
- Loops month-by-month, fetches Parquet files, normalizes column differences between green and yellow schemas (unified `pickup_datetime`, `dropoff_datetime`)
- Adds `taxi_type` and `extracted_at` columns, concatenates all DataFrames, returns the result
- Also generated the `requirements.txt`

**What the AI agent generated - staging asset (DuckDB SQL):**
- Dependencies set correctly to ingestion assets
- Materialization: `time_interval` with `pickup_datetime` as incremental key - deletes the date range, re-inserts from query results
- The Bruin panel's preview shows the compiled query: `BEGIN` → `DELETE WHERE pickup_datetime BETWEEN start AND end` → `INSERT`
- Important: the query itself must always filter by start/end date using the same incremental key
- Full column metadata and a no-duplicates custom check generated

**What the AI agent generated - report asset (DuckDB SQL):**
- Dependencies set to staging
- Materialization: `time_interval`, incremental key filtered correctly
- Aggregates at trip date, taxi type, and payment type level

**Conversational data analysis via MCP:**
The agent can query your data and answer questions in natural language:
- "Query the staging table and tell me how many days of data we have" → ran the query, returned 31 days (correct for the one month processed)
- "Which day had the highest number of trips and total fare?" → wrote and ran a `GROUP BY` + `ORDER BY LIMIT 5` query
- "In which asset are we aggregating data?" → correctly identified the reports asset and explained the aggregation logic

**Best practice:** in real workflows, go asset-by-asset rather than one giant prompt - this keeps you involved in every design choice and decision about the code.
