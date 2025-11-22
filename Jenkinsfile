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

        /* Apply only first time */
        stage('Create Backend Infra') {
            when { expression { ACTION == "APPLY" } }
            steps {
                withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
                    dir('backend') {
                        sh 'terraform init'
                        sh 'terraform apply -auto-approve'
                    }
                }
                script {
                    writeFile file: "backend_store.txt", text: """
BUCKET=$(terraform -chdir=backend output -raw bucket)
DDB=$(terraform -chdir=backend output -raw dynamodb_table)
"""
                }
            }
        }

        /* ALWAYS use stored backend values, never terraform output */
        stage('Generate backend.tf') {
            steps {
                script {
                    def store = readFile("backend_store.txt")
                    def bucket = store.split("\n")[0].replace("BUCKET=", "").trim()
                    def ddb = store.split("\n")[1].replace("DDB=", "").trim()

                    writeFile file: "backend.tf", text: """
terraform {
  backend "s3" {
    bucket         = "${bucket}"
    key            = "eks/terraform.tfstate"
    region         = "${AWS_REGION}"
    dynamodb_table = "${ddb}"
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

        stage('Delete Backend (optional)') {
            when { expression { ACTION == "DESTROY" } }
            steps {
                script {
                    def delete_backend = input(
                        message: "Delete S3 + DynamoDB backend also?",
                        parameters: [choice(name: 'DELETE', choices: "NO\nYES")]
                    )
                    if (delete_backend == "YES") {
                        withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
                            dir('backend') {
                                sh "terraform init"
                                sh "terraform destroy -auto-approve"
                            }
                        }
                        sh "rm -f backend_store.txt" // removes stored values
                    }
                }
            }
        }
    }
}
