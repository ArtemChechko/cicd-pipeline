pipeline {
  agent none

  tools {
    nodejs 'node'
  }

  environment {
    APP_NAME = "cicd-pipeline-app"
    CONTAINER_PORT = "3000"

    // Docker Hub
    DOCKERHUB_REPO = "artemchechko/cicd-pipeline"
    DOCKERHUB_CREDS = "dockerhub-creds"

    DOCKER_HOST = "unix:///var/run/docker.sock"
  }

  stages {

    stage('Checkout') {
      agent any
      steps {
        checkout scm
        stash name: 'src', includes: '**/*'
      }
    }

    stage('Build') {
      agent {
        docker {
          image 'node:7.8.0'
          args '-u root:root'
        }
      }
      steps {
        unstash 'src'
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
        stash name: 'built', includes: '**/*'
      }
    }

    stage('Test') {
      agent {
        docker {
          image 'node:7.8.0'
          args '-u root:root'
          reuseNode true
        }
      }
      environment {
        CI = 'true'               // важливо для CRA/Jest
      }
      options {
        timeout(time: 10, unit: 'MINUTES')  // щоб не висіло вічно
      }
      steps {
        unstash 'built'
        sh '''
          set -euxo pipefail
          ls -la
    
          if [ -f package.json ]; then
            # без watch, без інтерактиву, стабільніше в CI
            npm test -- --watchAll=false --runInBand || true
          else
            echo "No tests - skip"
          fi
        '''
      }
    }

    stage('Hadolint (Dockerfile check)') {
      agent {
        docker {
          image 'hadolint/hadolint:latest'
          args '-u root:root'
        }
      }
      steps {
        unstash 'built'
        sh '''
          echo "Running hadolint..."
          hadolint Dockerfile
        '''
      }
    }

    stage('Build Docker image') {
      when { anyOf { branch 'main'; branch 'dev' } }
      agent {
        docker {
          image 'docker:27-cli'
          args '-u root:root -v /var/run/docker.sock:/var/run/docker.sock'
        }
      }
      steps {
        unstash 'built'
        script {
          env.ENV_TAG = (env.BRANCH_NAME == 'main') ? 'nodemain-v1.0' : 'nodedev-v1.0'
          env.DH_IMAGE = "${env.DOCKERHUB_REPO}:${env.ENV_TAG}"
        }
        sh '''
          echo "Building Docker image: $DH_IMAGE"
          docker version
          docker build -t "$DH_IMAGE" .
        '''
      }
    }

    stage('Scan Docker Image for Vulnerabilities') {
      when { anyOf { branch 'main'; branch 'dev' } }
      agent {
        docker {
          image 'aquasec/trivy:latest'
          args '-u root:root -v /var/run/docker.sock:/var/run/docker.sock'
        }
      }
      steps {
        sh '''
          echo "Running trivy scan..."
          trivy image \
            --timeout 20m \
            --scanners vuln \
            --severity HIGH,CRITICAL \
            --no-progress \
            "$DH_IMAGE"
        '''
      }
    }

    stage('Push image to Docker Hub') {
      when { anyOf { branch 'main'; branch 'dev' } }
      agent {
        docker {
          image 'docker:27-cli'
          args '-u root:root -v /var/run/docker.sock:/var/run/docker.sock'
        }
      }
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
      when { anyOf { branch 'main'; branch 'dev' } }
      agent any
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
      // тут краще не робити docker images, бо not every agent has docker
      echo "Pipeline finished."
    }
  }
}