pipeline {
    agent any

    environment {
        AWS_REGION = "ap-south-1"
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/ajitesh70/terraform-eks.git'
            }
        }

        stage('Terraform Init') {
            steps {
                withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
                    sh '''
                        terraform init
                    '''
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                sh '''
                    terraform fmt -recursive
                    terraform validate
                '''
            }
        }

        stage('Terraform Plan') {
            steps {
                withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
                    sh '''
                        terraform plan -out=tfplan
                    '''
                }
            }
        }

        stage('Approval') {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    input message: "Do you want to APPLY Terraform changes?"
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
                    sh '''
                        terraform apply -auto-approve tfplan
                    '''
                }
            }
        }

        stage('Update Kubeconfig') {
            steps {
                withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
                    sh '''
                        CLUSTER=$(terraform output -raw cluster_name)
                        echo "Updating kubeconfig for cluster: $CLUSTER"
                        aws eks update-kubeconfig --name $CLUSTER --region ${AWS_REGION}
                    '''
                }
            }
        }
    }
}
