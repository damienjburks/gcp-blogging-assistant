pipeline {
    agent any

    options {
        disableConcurrentBuilds()
    }
    
    environment {
        SNYK_TOKEN = credentials('snyk-api-token')
        TF_TOKEN_app_terraform_io = credentials('terraform-cloud')
        SNYK_ORG_NAME = 'dsb-6YmccYk2Hr2e2suHMxA4KG'
        SONAR_TOKEN = credentials('sonar-analysis')
        SONAR_PROJECT_KEY = 'gcp-dsb-blogging-assistant'
        NEXUS_DOCKER_REGISTRY = '10.0.0.22:8082'
    }

    stages {
        stage('Clone') {
            steps {
                checkout scmGit(branches: [[name: '*/main']], extensions: [], userRemoteConfigs: [[credentialsId: 'Gitea PAT', url: 'http://10.0.0.22/damien/gcp-dsb-blogging-assistant.git']])
            }
        }
        stage('Python Build') {
            steps {
                sh '''
                python3 -m venv .env
                . .env/bin/activate
                pip install -r src/requirements.txt
                pip freeze > src/requirements.txt
                '''
            }
        }
        stage('Security Scan'){
            parallel {
                stage('Sonar Scan') {
                    steps {
                        script {
                            try{
                                withSonarQubeEnv(installationName: 'Sonar Server', credentialsId: 'sonar-analysis') {
                                    sh '''
                                    docker run --rm \
                                    -e SONAR_HOST_URL="${SONAR_HOST_URL}" \
                                    -e SONAR_TOKEN="${SONAR_TOKEN}" \
                                    -v "$(pwd):/usr/src" \
                                    ${NEXUS_DOCKER_REGISTRY}/sonarsource/sonar-scanner-cli \
                                    -Dsonar.projectKey="${SONAR_PROJECT_KEY}" \
                                    -Dsonar.qualitygate.wait=true \
                                    -Dsonar.sources=.
                                    '''
                                }
                            } catch (Exception e) {
                                // Handle the error
                                echo "Quality Qate check has failed: ${e}"
                                currentBuild.result = 'UNSTABLE' // Mark the build as unstable instead of failing
                            }
                        }
                    }
                }
                stage('Synk Scan'){
                    steps{
                        . .env/bin/activate
                        sh 'snyk test --file=src/requirements.txt --org=${SNYK_ORG_NAME}'
                        sh 'snyk iac test --severity-threshold=high --org=${SNYK_ORG_NAME} --report'
                    }
                }
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
