variable "credentials" {
  description = "de-zoomcamp credentials"
  default     = ""
}

variable "project" {
  description = "Project"
  default     = "dtc-de-410018"
}

variable "region" {
  description = "Region"
  default     = "europe-west3"
}

variable "location" {
  description = "Project Location"
  default     = "EU"
}

variable "bigquery_dataset_name" {
  description = "Homework 1 BigQuery Dataset"
  default     = "homework1_dataset_410018"
}

variable "gcp_bucket_name" {
  description = "Homework 1 Bucket Name"
  default     = "bucket-410018"
}

variable "gcp_storage_class" {
  description = "Bucket storage class"
  default     = "STANDARD"
}