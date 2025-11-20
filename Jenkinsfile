pipeline {
    agent any

    environment {
        AWS_REGION = "ap-south-1"
        AWS_CREDS  = "aws-creds"       // Jenkins AWS credential ID
    }

    stages {

        stage('Checkout Infra Code') {
            steps {
                git branch: 'main', url: 'https://github.com/ajitesh70/terraform-eks.git'
            }
        }

        stage('Terraform Init') {
            steps {
                withAWS(credentials: AWS_CREDS, region: AWS_REGION) {
                    sh '''
                        terraform init
                    '''
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                sh '''
                    echo "Running Terraform Format..."
                    terraform fmt -recursive

                    echo "Running Terraform Validate..."
                    terraform validate
                '''
            }
        }

        stage('Terraform Plan') {
            steps {
                withAWS(credentials: AWS_CREDS, region: AWS_REGION) {
                    sh '''
                        terraform plan -out=tfplan
                    '''
                }
            }
        }

        stage('Approval Required') {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    input message: "Do you want to APPLY Terraform changes?"
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                withAWS(credentials: AWS_CREDS, region: AWS_REGION) {
                    sh '''
                        terraform apply -auto-approve tfplan
                    '''
                }
            }
        }

        stage('Update kubeconfig') {
            steps {
                withAWS(credentials: AWS_CREDS, region: AWS_REGION) {
                    sh '''
                        CLUSTER=$(terraform output -raw cluster_name)
                        echo "Updating kubeconfig for cluster: $CLUSTER"
                        aws eks update-kubeconfig --name "$CLUSTER" --region $AWS_REGION
                    '''
                }
            }
        }

    }
}
