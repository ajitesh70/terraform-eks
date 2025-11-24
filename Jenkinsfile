pipeline {
    agent any

    environment {
        AWS_REGION      = "ap-south-1"
        BUCKET_NAME     = "ajitesh-tf-backend"     // NEW bucket you created
        LOCK_TABLE_NAME = "terraform-lock"        // NEW DynamoDB table you created
        CLUSTER_NAME    = "demo-eks"              // EKS cluster name
        ACTION = ""
    }

    stages {

        stage('Checkout') {
            steps {
                cleanWs()
                git branch: 'main', url: 'https://github.com/ajitesh70/terraform-eks.git'
            }
        }

        stage('Select Action: APPLY or DESTROY') {
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

        stage('Generate backend.tf') {
            steps {
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

        stage('Terraform Init') {
            steps {
                withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
                    sh "terraform init"
                }
            }
        }

        stage('Terraform Plan (APPLY only)') {
            when { expression { ACTION == "APPLY" } }
            steps {
                withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
                    sh "terraform plan -out=tfplan"
                }
            }
        }

        stage('Approval') {
            steps {
                input message: "Proceed with ${ACTION}?"
            }
        }

        /*********** SAFE DESTROY FIX (only executes when destroying) ***********/
        stage("Cleanup Workloads Before Destroy") {
            when { expression { ACTION == "DESTROY" } }
            steps {
                withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
                    script {
                        sh """
                        set +e
                        echo "Updating kubeconfig..."
                        aws eks update-kubeconfig --region ${AWS_REGION} --name ${CLUSTER_NAME}

                        echo "Deleting Kubernetes workloads before destroy..."
                        kubectl delete deployments --all -A || true
                        kubectl delete statefulsets --all -A || true
                        kubectl delete services --all -A || true
                        kubectl delete ingress --all -A || true
                        kubectl delete pods --all -A || true

                        echo "Waiting for load balancers and ENIs to detach..."
                        sleep 60
                        """
                    }
                }
            }
        }
        /************************************************************************/

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
