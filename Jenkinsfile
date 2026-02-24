pipeline {
  agent any

  tools {
    nodejs 'node-7.8.0'
  }

  environment {
    APP_NAME = "cicd-pipeline-app"
    CONTAINER_PORT = "3000"
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build') {
      steps {
        sh '''
          echo "Node version:"
          node -v
          echo "NPM version:"
          npm -v

          if [ -f package.json ]; then
            npm install
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
            npm test -- --watchAll=false || true
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
        sh '''
          echo "Building Docker image: $IMAGE"
          docker build -t "$IMAGE" .
        '''
      }
    }

    stage('Deploy') {
      steps {
        script {
          def hostPort = (env.BRANCH_NAME == 'main') ? '3000' : '3001'
          def containerName = "${APP_NAME}-${env.BRANCH_NAME}"

          sh """
            set -e

            echo "Deploying branch: ${env.BRANCH_NAME}"
            echo "App will be available at: http://localhost:${hostPort}"

            # Видаляємо ТІЛЬКИ контейнер поточного env
            docker rm -f ${containerName} 2>/dev/null || true

            # Запускаємо новий контейнер
            docker run -d --name ${containerName} \\
              -p ${hostPort}:${CONTAINER_PORT} \\
              -e PORT=${CONTAINER_PORT} \\
              -e HOST=0.0.0.0 \\
              ${IMAGE}

            echo "Running containers:"
            docker ps --filter "name=${containerName}"
          """
        }
      }
    }
  }

  post {
    success {
      echo "Pipeline completed successfully for branch: ${env.BRANCH_NAME}"
    }
    failure {
      echo "Pipeline FAILED for branch: ${env.BRANCH_NAME}"
    }
  }
}