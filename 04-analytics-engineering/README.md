# Week 4: Analytics Engineering

## 4.1.1 - Analytics Engineering Basics

### 1 - What ist `Analytics Engineering`

![roles](images/roles.jpg)

### Tooling

- Relevant sections of the tooling are here:
    - Data Modleing
    - Data Presentation

![tooling](images/tooling.jpg)


### 2 - Data Modeling Concepts

![etl-vs-elt](images/etl-vs-elt.jpg)

**ETL (Extract, Transform, Load)**
1. `Extract` data from source
2. `Transform` the data
3. `Load` data to data warehouse

Properties of ETL:
- Longer to implement, due to the requirement to transform the data
- More stable and compliant data, because the data is "clean"


**ELT (Extract, Load, Transform)**
1. `Extract` data from source 
2. `Load` data to data warehouse
3. `Transform` the data in the data warehouse

Properties of ETL:
- Faster and more flexible, since data is already loaded in the data warehouse after extraction
- Data warehouse usually cheaper than storing the data locally


### Kimball's Dimensional Modeling

**Objective**
- Deliver data understandable to a business user
- Deliver fast query performance

**Approach**: Prioritize user understandability and query performance over non-redundant data (3NF)

**Other approaches**
- Bill Inmon
- Data Vault

### Elements of dimensional modeling

**Facts tables**
- Measurements, metrics or facts about a business
- Correspond to a *business process*
- Like "Verbs"
- *Dimensions* provide context to the fact table

**Dimensions tables**
- Corresponds to a business *entity*
- Provides context to a business process
- Like "Nouns" (*customer*, *product*, ...)

![eodm](images/eodm.jpg)

### Architecture of Dimensional Modeling

**Analogy**: From buying ingredients to serving food at a resturant

- **`Stage Area`** (Buying ingredients)
    - Contains new raw data
    - Not meant to be exposed to everyone

- **`Processing Area`** (Cooking ingredients)
    - From raw data to data models
    - Focusses on efficiency
    - Ensuring standards

- **`Presentation Area`** (Serving food)
    - Final presentation of the data
    - Exposure to business stakeholder

## 4.1.2 - What is `dbt`?

`dbt` is a transformation workflow, that allows anyone that knows SQL or Python to deploy analytics code, following software engineering best practices like modularity, portability, CI/CD and documentation.

![dbt1](images/dbt1.jpg)

- Sits on top of Data Warehouse
- Helps to transform the data to something presentablev e.g. with BI Tools or data comsumers (other applications)

### How does `dbt` work?

![dbt2](images/dbt2.jpg)

### How to use `dbt`?

**`dbt Core`**
-  Open-source project that allows the data transformation
- Builds and runs a dbt project (`.sql` and `.yml` files)
- Introduces SQL compilation logic, macros and database adapters
- Includes a CLI interface to run dbt commands locally
- FOSS

**`dbt Cloud`**: SaaS application to develop and manage dbt projects
- Web-based IDE and cloud CLI to develop, run and test dbt project
- Managed environment
- Jobs orchestration
- Logging and Alerting
- Integrated documentation
- Admin and metadata API
- Semtantic Layer

### How are we going to use `dbt`?

**BigQuery**
- Development using Cloud IDE
- No local installation of `dbt core`

**Postgres**
- Development using local IDE of your choice
- Local installation of `dbt core` connecting to the Postgres database
- Running `dbt models` throught the CLI

![dbt3](images/dbt3.jpg)

## 4.2.1 - Start Your dbt Project: BigQuery and dbt Cloud (Alternative A)

### Create a new `dbt` project

`dbt` provides a starte project with a basic structure to ubild upon. 
- Repo: https://github.com/dbt-labs/dbt-starter-project
- Local adapted version: [dbt_project.yml](code/dbt_project.yml)

There are 2 ways to use the starte project:
- **With the `CLI`**
    - After havin installed `dbt` locally and setup the `profiles.yml`, run `dbt init` in the path we want to start the project to clone the starter project
- **With `dbt cloud`**
    - After having set up the dbt cloud credentials (repo and data warehouse) we can start a project from the web-based IDE

![dbt_project](images/dbt_project.jpg)

###  Project Setup

- Create a free `dbt`-account on https://www.getdbt.com/
- Create a new project:
    - Name the project
    - Choose connection (here: BigQuery)
    - Establish the connection between dbt and BigQuery
    - Set the required parameters


## 4.2.2 - Start Your dbt Project: Postgres and dbt Core Locally (Alternative B)
