# data-engineering-material
My study material to the Data Engineering class by DataTalks.Club.

## Syllabus

### [Module 1: Introduction & Prerequisites](01-docker-terraform)

* Course overview
* Introduction to GCP
* Docker and docker-compose
* Running Postgres locally with Docker
* Setting up infrastructure on GCP with Terraform
* Preparing the environment for the course
* Homework

### [Module 2: Workflow Orchestration](02-workflow-orchestration/)
* Data Lake
* Workflow orchestration
* Workflow orchestration with Mage
* Homework

### [Workshop 1: Data Ingestion](workshop-1-data-ingestion-with-dlt)

* Reading from apis
* Building scalable pipelines
* Normalising data
* Incremental loading
* Homework

### [Module 3: Data Warehouse](03-data-warehouse/)

* Data Warehouse
* BigQuery
* Partitioning and clustering
* BigQuery best practices
* Internals of BigQuery
* BigQuery Machine Learning

### [Module 4: Analytics engineering](04-analytics-engineering/)

* Basics of analytics engineering
* dbt (data build tool)
* BigQuery and dbt
* Postgres and dbt
* dbt models
* Testing and documenting
* Deployment to the cloud and locally
* Visualizing the data with google data studio and metabase

### [Module 5: Batch processing](05-batch/)

* Batch processing
* What is Spark
* Spark Dataframes
* Spark SQL
* Internals: GroupBy and joins


### Technologies used
- `Google Cloud Platform (GCP)`: Cloud-based auto-scaling platform by Google
    - `Google Cloud Storage (GCS)`: Data Lake
    - `BigQuery`: Data Warehouse
- `Terraform`: Infrastructure-as-Code (IaC)
- `Docker`: Containerization
- `SQL`: Data Analysis & Exploration
- `Mage`: Workflow Orchestration
- `dbt`: Data Transformation
- `Spark`: Distributed Processing
- `Kafka`: Streaming

### Tools used
- Docker and docker-compose
- Python3
- Google Cloud SDK
- Terraform

![arch_2](images/arch_2.jpeg)