pipeline {
  agent any

  tools {
    nodejs 'node'
  }

  environment {
    APP_NAME = "cicd-pipeline-app"
    CONTAINER_PORT = "3000"

    // Docker Hub
    DOCKERHUB_REPO = "artemchechko/cicd-pipeline"
    DOCKERHUB_CREDS = "dockerhub-creds"
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

    stage('Hadolint (Dockerfile check)') {
      steps {
        sh '''
          echo "Running hadolint..."
          docker run --rm -i hadolint/hadolint < Dockerfile
        '''
      }
    }

    stage('Build Docker image') {
      steps {
        script {
          // Stable tags per env (advanced requirement)
          env.ENV_TAG = (env.BRANCH_NAME == 'main') ? 'nodemain-v1.0' : 'nodedev-v1.0'
          env.DH_IMAGE = "${env.DOCKERHUB_REPO}:${env.ENV_TAG}"
        }
        sh '''
          echo "Building Docker image: $DH_IMAGE"
          docker build -t "$DH_IMAGE" .
        '''
      }
    }

    stage('Scan Docker Image for Vulnerabilities') {
      steps {
        script {
          def vulnerabilities = sh(
            script: """
              docker run --rm \
                -v /var/run/docker.sock:/var/run/docker.sock \
                aquasec/trivy:latest image \
                --timeout 20m \
                --scanners vuln \
                --severity HIGH,CRITICAL \
                --no-progress \
                ${env.DH_IMAGE}
            """,
            returnStdout: true
          ).trim()
    
          echo "Vulnerability Report:\n${vulnerabilities}"
        }
      }
    }

    stage('Push image to Docker Hub') {
      steps {
        withCredentials([usernamePassword(credentialsId: "${DOCKERHUB_CREDS}", usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
          sh '''
            echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin
            docker push "$DH_IMAGE"
            docker logout
          '''
        }
      }
    }

    stage('Trigger deploy pipeline') {
      steps {
        script {
          def jobName = (env.BRANCH_NAME == 'main') ? 'Deploy_to_main' : 'Deploy_to_dev'
          echo "Triggering downstream job: ${jobName}"
          build job: jobName, wait: true
        }
      }
    }
  }

  post {
    success {
      echo "CICD completed successfully for branch: ${env.BRANCH_NAME}"
    }
    failure {
      echo "CICD FAILED for branch: ${env.BRANCH_NAME}"
    }
    always {
      sh 'docker images | head -n 20 || true'
    }
  }
}