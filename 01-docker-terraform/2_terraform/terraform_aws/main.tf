terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws",
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                   = var.region
  profile                  = var.profile
  shared_credentials_files = ["~/.aws/credentials"]
}

####################
### EC2 Instance ###
####################

resource "aws_instance" "demo-ec2-instance" {
  ami           = "ami-0df8c184d5f6ae949" # AWS Linux 2023
  instance_type = "t2.micro"              # Included in free tier
  tags = {
    Name = "demo-ec2-instance"
  }
}


#################
### S3 Bucket ###
#################

resource "aws_s3_bucket" "demo-s3-bucket" {
  bucket        = replace("${var.bucket_name}-${var.profile}", "_", "-")  # replacing "_" -> not allowed in s3
  force_destroy = true
  tags = {
    Name = "${var.bucket_name}-${var.profile}"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "demo-bucket-lifecycle" {
  bucket = aws_s3_bucket.demo-s3-bucket.id

  rule {
    id     = "AbortIncompleteMultipartUpload"
    status = "Enabled"

    expiration {
      days = 1
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}


#################################
### AWS Glue Catalog Database ###
#################################

resource "aws_glue_catalog_database" "demo-glue-database" {
  name = "${var.glue_database_name}-${var.profile}"
}

