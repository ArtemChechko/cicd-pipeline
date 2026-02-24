pipeline {
  agent any

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }
    stage('Build') {
      steps { sh 'echo build stage' }
    }
    stage('Test') {
      steps { sh 'echo test stage' }
    }
    stage('Build Docker image') {
      steps { sh 'docker --version && echo docker-build' }
    }
    stage('Deploy') {
      steps {
        script {
          def hostPort = (env.BRANCH_NAME == 'main') ? '3000' : '3001'
          sh "echo Deploying ${env.BRANCH_NAME} on port ${hostPort}"
        }
      }
    }
  }
}