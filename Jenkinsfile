pipeline {
  agent any

  environment {
    APP_NAME = "cicd-pipeline-app"
    CONTAINER_PORT = "3000"   // порт всередині контейнера
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Build') {
      steps {
        sh '''
          if [ -f package.json ]; then
            npm ci || npm install
            npm run build || true
          else
            echo "No package.json - skip build"
          fi
        '''
      }
    }

    stage('Test') {
      steps {
        sh '''
          if [ -f package.json ]; then
            npm test || true
          else
            echo "No tests - skip"
          fi
        '''
      }
    }

    stage('Build Docker image') {
      steps {
        script {
          env.IMAGE = "cicd-pipeline:${env.BRANCH_NAME}-${env.BUILD_NUMBER}"
        }
        sh 'docker build -t "$IMAGE" .'
      }
    }

    stage('Deploy') {
      steps {
        script {
          def hostPort = (env.BRANCH_NAME == 'main') ? '3000' : '3001'
          def containerName = "${APP_NAME}-${env.BRANCH_NAME}"

          sh """
            set -e
            echo "Deploy ${env.BRANCH_NAME} -> http://localhost:${hostPort}"

            docker rm -f ${containerName} 2>/dev/null || true

            docker run -d --name ${containerName} \\
              -p ${hostPort}:${CONTAINER_PORT} \\
              -e PORT=${CONTAINER_PORT} \\
              ${IMAGE}

            docker ps --filter "name=${containerName}"
          """
        }
      }
    }
  }
}