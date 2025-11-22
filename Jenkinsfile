pipeline {
    agent any

    environment {
        AWS_REGION = "ap-south-1"
        ACTION = ""   // will become APPLY or DESTROY dynamically
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

        /* 🔥 Ask user: Apply or Destroy infrastructure */
        stage('Select Action (Apply / Destroy)') {
            steps {
                script {
                    ACTION = input(
                        message: "Choose Terraform Action",
                        parameters: [
                            choice(name: 'ACTION', choices: "APPLY\nDESTROY", description: "Select action")
                        ]
                    )
                    echo "Selected action: ${ACTION}"
                }
            }
        }

        /* 🚀 Create backend only when APPLY is selected */
        stage('Create Terraform Backend Infra') {
            when { expression { ACTION == "APPLY" } }
            steps {
                withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
                    dir('backend') {
                        sh 'terraform init'
                        sh 'terraform apply -auto-approve'
                    }
                }
            }
        }

        /* 📌 Configure backend.tf dynamically */
        stage('Configure Backend') {
            when { expression { ACTION == "APPLY" } }
            steps {
                script {
                    def bucket = sh(script: 'terraform -chdir=backend output -raw bucket', returnStdout: true).trim()
                    def dynamodb_table = sh(script: 'terraform -chdir=backend output -raw dynamodb_table', returnStdout: true).trim()

                    writeFile file: "backend.tf", text: """
terraform {
  backend "s3" {
    bucket         = "${bucket}"
    key            = "eks/terraform.tfstate"
    region         = "${AWS_REGION}"
    dynamodb_table = "${dynamodb_table}"
  }
}
"""
                }
            }
        }

        /* 🧠 Terraform Init — required for both APPLY and DESTROY */
        stage('Terraform Init') {
            steps {
                withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
                    sh "terraform init"
                }
            }
        }

        stage('Terraform Plan (Only for APPLY)') {
            when { expression { ACTION == "APPLY" } }
            steps {
                withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
                    sh "terraform plan -out=tfplan"
                }
            }
        }

        stage('Approval Before Action') {
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    input message: "Proceed with ${ACTION}?"
                }
            }
        }

        /* 🟢 APPLY or ❌ DESTROY based on selection */
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

        /* ⚠ Optional: Ask if backend should be deleted too */
        stage('Destroy Backend Infra (OPTIONAL)') {
            when { expression { ACTION == "DESTROY" } }
            steps {
                script {
                    def delete_backend = input(
                        message: "Infra destroyed successfully. Delete Backend Resources also?",
                        parameters: [
                            choice(name: 'CONFIRM', choices: "NO\nYES", description: "Backend = S3 bucket & DynamoDB lock table")
                        ]
                    )
                    if (delete_backend == "YES") {
                        withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
                            dir('backend') {
                                sh "terraform init"
                                sh "terraform destroy -auto-approve"
                            }
                        }
                    }
                }
            }
        }
    }
}
