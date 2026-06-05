pipeline {
    agent any

    options {
        skipDefaultCheckout(true)
    }

    environment {
        DOCKER_IMAGE = 'artemchechko/cicd-pipeline'
        DOCKER_TAG = "${env.BUILD_NUMBER}"
    }

    stages {
        stage('Git Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Application Build') {
            steps {
                sh '''
                    chmod +x scripts/build.sh
                    ./scripts/build.sh
                '''
            }
        }

        stage('Test') {
            steps {
                sh '''
                    chmod +x scripts/test.sh
                    ./scripts/test.sh
                '''
            }
        }

        stage('Docker Image Build') {
            steps {
                script {
                    docker.build("${DOCKER_IMAGE}:${DOCKER_TAG}")
                }
            }
        }

        stage('Docker Image Push') {
            steps {
                script {
                    docker.withRegistry('https://registry.hub.docker.com', 'dockerhub') {
                        docker.image("${DOCKER_IMAGE}:${DOCKER_TAG}").push()
                        docker.image("${DOCKER_IMAGE}:${DOCKER_TAG}").push('latest')
                    }
                }
            }
        }
    }
}
