pipeline {
    agent any

    environment {
        AWS_REGION = "ap-south-1"
        BUCKET_NAME = "ajitesh-tf-backend-lxjg6stb"        // update once
        LOCK_TABLE_NAME = "terraform-lock-lxjg6stb"        // update once
        ACTION = ""
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

        stage('Select Action (Apply / Destroy)') {
            steps {
                script {
                    ACTION = input(
                        message: "Select Terraform Action",
                        parameters: [choice(name: 'ACTION', choices: "APPLY\nDESTROY")]
                    )
                    echo "Selected: ${ACTION}"
                }
            }
        }

        /* 💥 Always generate backend.tf (no output dependency) */
        stage('Generate backend.tf') {
            steps {
                script {
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
        }

        stage('Terraform Init') {
            steps {
                withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
                    sh "terraform init"
                }
            }
        }

        stage('Terraform Plan (Apply only)') {
            when { expression { ACTION == "APPLY" } }
            steps {
                withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
                    sh "terraform plan -out=tfplan"
                }
            }
        }

        stage('Approval Before Action') {
            steps {
                input message: "Proceed with ${ACTION}?"
            }
        }

        stage('Execute Terraform') {
            steps {
                withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
                    script {
                        if (ACTION == "APPLY") {
                            sh "terraform apply -auto-approve tfplan"
                        } else {
                            sh "terraform destroy -auto-approve"
                        }
                    }
                }
            }
        }
    }
}
