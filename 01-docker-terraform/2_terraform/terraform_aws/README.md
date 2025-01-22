### Concepts
* [Terraform_overview](../1_terraform_overview.md)



### Execution

```shell
# Set the aws access keys for current command line session
aws configure --profile terraform_aws_intro

# Initialize state file (.tfstate)
terraform init

# Check changes to new infra plan
terraform plan -var="profile=<your-profile-name>"
```

```shell
# Create new infra
terraform apply -var="profile=<your-profile-name>"
```

```shell
# Delete infra after your work, to avoid costs on any running services
terraform destroy -var="profile=<your-profile-name>"
```
