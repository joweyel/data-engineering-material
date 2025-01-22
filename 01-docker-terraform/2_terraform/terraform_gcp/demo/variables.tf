variable "project" {
  description = "Project"
  default     = "dtc-de-410018"
}

variable "credentials" {
  description = "My Credentials"
  default     = "/home/user/.gcp/dtc-de-410018-terraform.json"
}

variable "region" {
  description = "Region"
  default     = "europe-west10-a"
}

variable "location" {
  description = "Project Location"
  default     = "EU"
}

variable "bq_dataset_name" {
  description = "My BigQuery Dataset Name"
  default     = "demo_dataset"
}

variable "gcs_bucket_name" {
  description = "My Storage Bucket Name"
  default     = "dtc-de-410018-terra-bucket"
}

variable "gcs_storage_class" {
  description = "Bucket Storage Class"
  default     = "STANDARD"
}