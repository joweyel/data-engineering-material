# AWS Overview

## Project infrastructure modules in AWS:
- `S3 Bucket`: Data Lake
- `EC2 Instance`: VM on AWS
- `AWS Glue Data catalog database`: empty database for AWS's managed ETL services


## Initial Setup

> **`Important`**: The IAM user created here is only used for the terraform intro and is therefore limited in its permissions and is only for programmatic access through the console. The required policies for the creation of resources is attached by a privileged user, that is mentioned in step 2 of the setup.

### Create AWS root-account
This step is optional if you already have an AWS account. Otherwise follow the instructions here: https://aws.amazon.com/resources/create-account/

### Create AWS IAM account with admin privileges 

It is generally recommended to not use your AWS root accuont for your daily needs, even if you need admin privileges. Instead you should create an IAM user with admin privileges and "shelve" the root user. 

The following youtube-video explains this straightforward process in only 4 minutes:

[![YouTube Video](https://img.youtube.com/vi/b6sT5JgWAss/0.jpg)](https://www.youtube.com/watch?v=b6sT5JgWAss)

This account can be use from now on for mostly everything with a few exceptions (not relevant for this class).


### Create AWS IAM account and Access Keys for terraform introduction

> `Pre-requisite`: Log in to the previously created AWS IAM account with admin privileges.

1. Go to `IAM`, then click `Users` on the left side of the screen, then `Create user`
2. <u>Specify user Details</u>
    - **`User name`**: `terraform_aws_intro`
3. <u>Set permissions</u>   
    - Attach policies directly:
      - `AmazonEC2FullAccess`
      - `AmazonS3FullAccess`
      - `AWSGlueConsoleFullAccess`
    
    > `Disclaimer`: The permissions are pretty open, but for a tutorial purpose sufficient. In practce you would use Roles and dynamically attach them to your newly created resources. This is however relatively complex, which is why it is omitted here. Also the usage of a distingc VPC with subnets is usually the way to go but for the introductory tutorial the default vpc and subnets should suffice.
4. <u>Create Access Keys</u>
   - Select `terraform_aws_intro` from the list of users
   - Click on `Create access key`
   - **`Use case`**: `Command Line Interface (CLI)`
   - Click `Create access key`
   - Download the access keys as csv to a secure location for later

### Setting up AWS access key credentials for Terraform

Configure the AWS access key credentials on your local machine:
```bash
aws configure --profile terraform_aws_intro
```
You will be prompted to insert the access key id, the secret access key, the region and output format of AWS CLI results (default: json). The credentials that are now stored on your computer under `~/.aws/` and can accessed in the terraform script in the workshop below.


> **`Important`**: In comparison to the GCP tutorial, this tutorial will not create anything Data Warehouse / Dataset related due to differences in resources between GCP and AWS resources. There is for example no equivalent to the BigQuery Dataset resource in AWS, which is why I decided to just set up a EC2 instance instead as well as a Glue Data catalog database. The EC2 instance is a cloud VM and the Glue Data catalog database is an empty database for the managed ETL servive AWS Glue.

### Terraform Workshop to create AWS Infrastructure
Continue [here](./terraform_aws/): `01-docker-terraform/2_terraform/terraform_aws`