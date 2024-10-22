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
        NEXUS_DOCKER_REGISTRY = 'nexus.dsb-hub.local'
    }

    stages {
        stage('Clone') {
            steps {
                checkout scmGit(
                    branches: [[name: '*/main']], 
                    extensions: [], 
                    userRemoteConfigs: [
                        [credentialsId: 'Gitea PAT', url: 'https://dsb-hub.local/damien/gcp-dsb-blogging-assistant.git']
                    ]
                )
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
        stage('Syntax Check') {
            parallel {
                stage('Format Check'){
                    steps {
                        sh '''
                        . .env/bin/activate
                        black --check src/
                        '''
                    }
                }
                stage('Lint Check'){
                    steps {
                        sh '''
                        echo 'WIP'
                        '''
                    }
                }
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
                        sh '''
                        . .env/bin/activate
                        snyk test --file=src/requirements.txt --org=${SNYK_ORG_NAME} --report
                        snyk iac test --severity-threshold=high --org=${SNYK_ORG_NAME} --report
                        '''
                    }
                }
                stage('Trivy Scan') {
                    steps {
                        sh '''
                            trivy config --exit-code 0 --severity HIGH,CRITICAL ./ > trivy-report.txt
                        '''
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
    }
    post {
        always {
            archiveArtifacts artifacts: 'trivy-report.txt', allowEmptyArchive: true
            cleanWs()
        }
    }
}
