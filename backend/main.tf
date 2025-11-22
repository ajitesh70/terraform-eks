terraform {
  required_version = ">= 1.0.0"
}

provider "aws" {
  region = "ap-south-1"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "tf_state" {
  bucket        = "ajitesh-tf-backend-${random_string.suffix.id}"
  force_destroy = true
}

resource "aws_dynamodb_table" "tf_lock" {
  name         = "terraform-lock-${random_string.suffix.id}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

output "bucket" {
  value = aws_s3_bucket.tf_state.bucket
}

output "dynamodb_table" {
  value = aws_dynamodb_table.tf_lock.name
}
