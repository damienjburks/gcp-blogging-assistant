pipeline {
    agent any
    
    triggers {
        cron('H 9 * * *') // This schedules the job to run once a day at 9AM
    }

    options {
        disableConcurrentBuilds()
    }
    
    environment {
        SNYK_TOKEN = credentials('snyk-api-token')
        TF_TOKEN_app_terraform_io = credentials('terraform-cloud')
        SNYK_ORG_NAME = 'dsb-6YmccYk2Hr2e2suHMxA4KG'
    }

    stages {
        stage('Clone') {
            steps {
                checkout scmGit(branches: [[name: '*/main']], extensions: [], userRemoteConfigs: [[credentialsId: 'Gitea PAT', url: 'http://10.0.0.22/damien/terraform-starter.git']])
            }
        }
        stage('Synk Scan'){
            steps{
                sh 'snyk iac test --severity-threshold=high --org=${SNYK_ORG_NAME} --report'
            }
        }
        stage('Terraform Apply') {
            steps {
                script {
                    sh 'terraform init'
                    sh 'terraform apply -auto-approve'
                }
            }
        }
        stage('Terraform Destroy') {
            steps {
                script {
                    sh 'terraform destroy -auto-approve'
                }
            }
        }
    }
}
