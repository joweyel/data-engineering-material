# Module 2: Workflow Orchestration

## 2.2.1 Workflow Orchestration Introduction

### What is Workflow Orchestration?
- Is a process where multiple components are arranged (like in an orchestra) to work in the correct way / order
- Workflow orchestration tools are for example: Ariflow, Mage, Prefect, Kestra, ...

### What is Kestra?

- An All-In One Automation and Orchestration Platform

![alt text](images/kestra_1.jpg)

- Has options of...
  - No-Code: 
  - Low-Code
  - Full-Code
- Supports any language
  - Examples: Python, Julia, Ruby, R, JavaScript, C, ...
- Allows monitoring of Workflows and Executions
- Has Plugins for many tools and basically all cloud platforms

### Overview of Content
- Introduction to Kestra
- ETL: Extract data and load it to postgres
- ETL: Extract data and load it to Google Cloud
- Parameterizing Execution
- Scheduling and Backfills
- Install Kestra on the Cloud and sync your Flows with Git


## 2.2.2 Learn Kestra

To learn what Kestra is and how to use it, you should read the Kestra Blog and the accompanying videos on youtube.

### Getting Started with Kestra 
- [Website](https://kestra.io/blogs/2024-04-05-getting-started-with-kestra)
- [Video](https://youtu.be/a2BZ7vOihjg)

#### Properties
- Workflows are declared in yaml
- Each flow requires 3 properties
  - `id`: Name of the flow
  - `namespace`: Environment for your flow
  - `tasks`: List of tasks to execute in your flow

Example flow:
```yaml
id: getting_started
namespace: example
tasks:
  - id: hello_world
    type: io.kestra.core.tasks.log.Log
    message: Hello World!
```

#### Example Application
- Applications sends API request to github to ask number of stars that the Kestra Repo has
- Sends the results from github every hour to discord

The resulting flow and code look as follows:

<details>
<summary><b>flow</b></summary>

```yaml
id: hello-world
namespace: company.team

inputs:
  - id: kestra_logo
    type: STRING
    defaults: https://avatars.githubusercontent.com/u/59033362?s=48&v=4
  
  - id: discord_webhook
    type: STRING
    defaults: https://discord.com/api/webhooks/...  # replace with your own wbhook

tasks:
  - id: python_script
    type: io.kestra.plugin.scripts.python.Commands
    namespaceFiles:
      enabled: true
    beforeCommands:
      - python -m venv .venv
      - . .venv/bin/activate
      - pip install -r scripts/requirements.txt
    commands:
      - python scripts/api_example.py

  - id: output_gh_stars
    type: io.kestra.plugin.core.log.Log
    message: "Number of stars: {{ outputs.python_script.vars.gh_stars }}"
  
  - id: send_notification
    type: io.kestra.plugin.notifications.discord.DiscordExecution
    content: "Total of Github Stars: {{ outputs.python_script.vars.gh_stars }}"
    username: Kestra
    avatarUrl: "{{ inputs.kestra_logo }}"
    url: "{{ inputs.discord_webhook }}"


triggers:
  - id: hour_trigger
    type: io.kestra.plugin.core.trigger.Schedule
    cron: 0 * * * *
    disabled: false
```

</details>

<details>
<summary><b>scripts/api_example.py</b></summary>

```python
import requests
from kestra import Kestra

r = requests.get("https://api.github.com/repos/kestra-io/kestra")
gh_stars = r.json()["stargazers_count"]
Kestra.outputs({"gh_stars": gh_stars})
```
</details>

<details>
<summary><b>scripts/requirements.txt</b></summary>

```txt
requests
kestra
```
</details>


### Kestra Beginner Tutorial
- [Website](https://kestra.io/docs/tutorial)
- [Playlist](https://www.youtube.com/playlist?list=PLEK3H8YwZn1oaSNybGnIfO03KC_jQVChL)


The very short videos in the playlist give a foundational knowledge of how kestra works. The notation in the videos is in some parts deprecated, so looking into the accompanying documentation is required to get an up-to-date understanding of kestra.

### Use Kestra with Docker Compose

- [Documentation](https://kestra.io/docs/installation/docker-compose)

A list of available Kestra Docker containers can be found in the dockumentation [here](https://kestra.io/docs/installation/docker#docker-image-tags). There is a major distinction between all the different Docker containers:
- **All Plugins**: 
  - `kestra/kestra:*`
- **No Plugins**: 
  - `kestra/kestra:*-no-plugins`


The [docker-compose.yaml](./docker-compose.yml) launches 4 docker container:
- `kestra`: a Kestra-Server
- `postgres`: a Postgres-Database to have persistent Kestra data
- `postgres_zoomcamp`: a Postgres-Database to store processed data in
- `pgadmin`: a pgAdmin instance to look into the data



## 2.2.3 ETL Pipelines with Postgres in Kestra

On this section the used data (NYC Taxi data) will be obtained from here: https://github.com/DataTalksClub/nyc-tlc-data/releases.

The overall goal is to: 
- **`Extract`**: Load the data from the git repository
- **`Transform`**: Process it with Kestra by merging the data
- **`Load`**: Save it to a database

Here the data has to be added for each month and combined into a table.

Start Kestra with this [docker-compose](docker-compose.yml):
```bash
docker-compose up
```

The Kastra-Flow that is used for the ETL Pipeline is [`postgres_taxi.yaml`](flows/postgres_taxi.yaml). The components are commented and are pretty self-expalnatory.

Accessing the ingested data with pgAdmin:
- Open pgAdmin at http://localhost:8085
- Log in with the credentials [here](docker-compose.yml#L86)
- Register a Server with the following connection configuration:
  - **Host name**:  postgres_zoomcamp
  - **Port**: 5432
  - **Maintenance database**: postgres-zoomcamp
  - **Username**: kestra



## 2.2.4 - Manage Scheduling and Backfills with Postgres in Kestra

In this section we learn how the application of the flow can be automated using scheduling and how backfills can be used for missed schedules in the past.