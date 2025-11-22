pipeline {
    agent any

    environment {
        AWS_REGION = "ap-south-1"
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
                        parameters: [
                            choice(name: 'ACTION', choices: "APPLY\nDESTROY", description: "APPLY = Create Infra, DESTROY = Delete Infra")
                        ]
                    )
                    echo "Selected: ${ACTION}"
                }
            }
        }

        /* 🚀 Always create backend.tf before both APPLY & DESTROY */
        stage('Generate backend.tf') {
            steps {
                script {
                    // These values were created first time and stored in backend/terraform.tfstate
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

        /* 🔥 Only build backend on APPLY (If not already built) */
        stage('Create Backend Infra (only first time)') {
            when { expression { ACTION == "APPLY" } }
            steps {
                withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
                    dir('backend') {
                        sh 'terraform init'
                        sh 'terraform apply -auto-approve || true'  // if bucket already exists, continue
                    }
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
                timeout(time: 30, unit: 'MINUTES') {
                    input message: "Proceed with ${ACTION}?"
                }
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

        /* Optional: Delete backend infra also */
        stage('Delete Backend (Optional)') {
            when { expression { ACTION == "DESTROY" } }
            steps {
                script {
                    def remove_backend = input(
                        message: "Cluster deleted. Delete S3 + DynamoDB too?",
                        parameters: [choice(name: 'DELETE', choices: "NO\nYES")]
                    )
                    if (remove_backend == "YES") {
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
