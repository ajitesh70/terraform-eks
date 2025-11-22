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

        stage('Terraform Init') {
            steps {
                withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
                    sh 'terraform init'
                }
            }
        }

        stage('Select Action') {
            steps {
                script {
                    ACTION = input(
                        id: "ACTION", message: "Select Terraform Action:",
                        parameters: [
                            choice(name: 'ACTION', choices: ["APPLY", "DESTROY"], description: 'Pick an action')
                        ]
                    )
                }
            }
        }

        stage('Execute Terraform') {
            steps {
                withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
                    script {
                        if (ACTION == "APPLY") {
                            sh """
                                terraform plan -out=tfplan
                                terraform apply -auto-approve tfplan
                            """
                        } else {
                            sh "terraform destroy -auto-approve"
                        }
                    }
                }
            }
        }
    }
}
