pipeline {
    agent any

    environment {
        AWS_REGION = "ap-south-1"
    }

    stages {

        stage('Clean Workspace') {
            steps { cleanWs() }
        }

        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/ajitesh70/terraform-eks.git'
            }
        }

        stage('Create Terraform Backend Infra') {
            steps {
                withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
                    dir('backend') {
                        sh 'terraform init'
                        sh 'terraform apply -auto-approve'
                    }
                }
            }
        }

        stage('Configure Backend') {
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

        stage('Terraform Plan') {
            steps {
                withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
                    sh "terraform plan -out=tfplan"
                }
            }
        }

        stage('Approval') {
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    input message: "Approve APPLY Terraform?"
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
                    sh "terraform apply -auto-approve tfplan"
                }
            }
        }

        stage('Update Kubeconfig') {
            steps {
                withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
                    sh '''
                        CLUSTER=$(terraform output -raw cluster_name)
                        aws eks update-kubeconfig --name $CLUSTER --region ${AWS_REGION}
                    '''
                }
            }
        }
    }
}
