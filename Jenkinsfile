pipeline {
    agent any

    environment {
        AWS_REGION = "ap-south-1"
        ACTION = ""
    }

    stages {

        stage('Clean Workspace') { steps { cleanWs() } }

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

        /* 🔥 First run only (creates backend resources) */
        stage('Create Backend Infra if needed') {
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

        /* 💯 Create backend.tf AFTER backend exists */
        stage('Generate backend.tf') {
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

        stage('Terraform Init') {
            steps {
                withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
                    sh "terraform init"
                }
            }
        }

        stage('Terraform Plan (only on APPLY)') {
            when { expression { ACTION == "APPLY" } }
            steps {
                withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
                    sh "terraform plan -out=tfplan"
                }
            }
        }

        stage('Approval Before Execute') {
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

        stage('Delete Backend (Optional)') {
            when { expression { ACTION == "DESTROY" } }
            steps {
                script {
                    def delete_backend = input(
                        message: "Cluster destroyed. Delete DynamoDB + S3 backend?",
                        parameters: [choice(name: 'DELETE', choices: "NO\nYES")]
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
