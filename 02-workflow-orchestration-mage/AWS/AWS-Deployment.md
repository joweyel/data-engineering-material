## 2.2.7 - Deployment Prerequisites
- Deploying Mage to AWS using Terraform

### Deployment (setting everything up)

- Install `terraform`
- Install `aws cli`
- Configuring `AWS Permissions`
- Mage Terraform templates
    - Instead of writing the terraform script yourself

## 2.2.7 - AWS Permissions

- The following policies have to be added to the Mage IAM-User on AWS:
    - `apply`: https://docs.mage.ai/production/deploying-to-cloud/aws/terraform-apply-policy
    - `destroy`: https://docs.mage.ai/production/deploying-to-cloud/aws/terraform-destroy-policy

- The roles are required for performing tasks in terraform later

## 2.2.7 - Deploying to AWS Part 1

Confirm that AWS is working and terraform is working as expected

- `AWS`:
```bash
# Add IAM user account for authentication
aws configure --profile <profile-name>
# List all available S3 buckets
aws s3 ls
```

## 2.2.7 - Deploying to AWS Part 2
Spin up Mage Server on AWS with Mage Terraform-template

```bash
git clone https://github.com/mage-ai/mage-ai-terraform-templates.git
cd mage-ai-terraform-templates/aws

# The usual terraform commands
terraform init
terraform fmt

# Adapting of `variables.tf` for your project
# Important: the region, access_key, secret_key

terraform plan
terraform apply
```

The created resources should be accessible over AWS.