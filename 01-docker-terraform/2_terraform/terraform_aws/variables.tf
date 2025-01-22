variable "profile" {
  description = "Name of AWS IAM user"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "S3 bucket name"
  type        = string
  default     = "demo-s3-bucket"
}

variable "glue_database_name" {
  description = "Name of Glue Catalog database"
  type        = string
  default     = "demo-database"
}