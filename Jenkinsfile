pipeline {
    agent any

    environment {
        AWS_REGION = "ap-south-1"
        BUCKET_NAME = "ajitesh-tf-backend-lxjg6stb"
        LOCK_TABLE_NAME = "terraform-lock-lxjg6stb"
    }

    stages {

        stage('Clean Workspace') {
            steps { cleanWs() }
        }

        stage('Checkout Terraform Code') {
            steps {
                git branch: 'main', url: 'https://github.com/ajitesh70/terraform-eks.git'
            }
        }

        stage('Generate backend.tf') {
            steps {
                writeFile file: "backend.tf", text: """
terraform {
  backend "s3" {
    bucket         = "${BUCKET_NAME}"
    key            = "eks/terraform.tfstate"
    region         = "${AWS_REGION}"
    dynamodb_table = "${LOCK_TABLE_NAME}"
  }
}
"""
            }
        }

        stage('Terraform Init') {
            steps {
                withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
                    sh "terraform init"
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
                    sh "terraform plan -out=tfplan"
                }
            }
        }

        stage('Approval Before Apply') {
            steps {
                input message: "Proceed with Terraform APPLY?"
            }
        }

        stage('Terraform Apply') {
            steps {
                withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
                    sh "terraform apply -auto-approve tfplan"
                }
            }
        }
    }
}
