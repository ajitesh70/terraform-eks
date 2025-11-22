pipeline {
    agent any
    parameters {
        choice(name: 'ACTION', choices: ['apply', 'destroy'], description: 'Select Terraform action')
    }
    environment {
        AWS_REGION = "ap-south-1"
    }

    stages {
        
        stage('Checkout Code') {
            steps {
                cleanWs()
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
                    bucket = sh(script: "terraform -chdir=backend output -raw bucket", returnStdout: true).trim()
                    lock_table = sh(script: "terraform -chdir=backend output -raw dynamodb_table", returnStdout: true).trim()

                    writeFile file: "backend.tf", text: """
terraform {
  backend "s3" {
    bucket         = "${bucket}"
    key            = "eks/terraform.tfstate"
    region         = "${AWS_REGION}"
    dynamodb_table = "${lock_table}"
    encrypt        = true
  }
}
"""
                }
            }
        }

        stage('Terraform Init') {
            steps {
                withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Plan') {
            when { expression { params.ACTION == 'apply' }}
            steps {
                withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
                    sh 'terraform plan -out tfplan'
                }
            }
        }

        stage('Terraform Apply or Destroy') {
            steps {
                withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
                    script {
                        if (params.ACTION == 'apply') {
                            sh 'terraform apply -auto-approve tfplan'
                        } else {
                            sh 'terraform destroy -auto-approve'
                        }
                    }
                }
            }
        }

        stage('Update Kubeconfig') {
            when { expression { params.ACTION == 'apply' }}
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
