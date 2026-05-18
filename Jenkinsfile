pipeline {
  agent {
    docker {
      image 'node:18-alpine'
      args '--network=host'
    }
  }

tools {
    nodejs 'NodeJS v26'
  }

  environment {
    APP_NAME    = 'kijanikiosk-payments'
    NEXUS_URL   = 'http://localhost:8081'
    NEXUS_REPO  = 'kijanikiosk-npm'
    GIT_SHA     = "${env.GIT_COMMIT ? env.GIT_COMMIT.take(7) : 'unknown'}"
    APP_VERSION = "1.0.0-${env.GIT_COMMIT ? env.GIT_COMMIT.take(7) : 'unknown'}"
  }

  options {
    timeout(time: 10, unit: 'MINUTES')
    buildDiscarder(logRotator(numToKeepStr: '10'))
    disableConcurrentBuilds()
  }

  stages {
    stage('Lint') {
      steps {
        dir('kijanikiosk-payments') {
          sh 'npm ci'
          sh 'npm run lint'
        }
      }
    }

    stage('Build') {
      steps {
        dir('kijanikiosk-payments') {
          sh 'npm run build'
          sh "echo 'Built version: ${APP_VERSION}'"
        }
      }
    }

    stage('Verify') {
      parallel {
        stage('Test') {
          steps {
            dir('kijanikiosk-payments') {
              sh 'mkdir -p test-results'
              sh 'npm test'
            }
          }
        }
        stage('Security Audit') {
          steps {
            dir('kijanikiosk-payments') {
              sh 'npm audit --audit-level=high || true'
            }
          }
        }
      }
    }

    stage('Archive') {
      steps {
        dir('kijanikiosk-payments') {
          sh 'npm pack dist/'
          sh "mv *.tgz ${APP_NAME}-${APP_VERSION}.tgz"
          fingerprint "${APP_NAME}-${APP_VERSION}.tgz"
          archiveArtifacts artifacts: "${APP_NAME}-${APP_VERSION}.tgz",
                           fingerprint: true
        }
      }
    }

    stage('Publish') {
      steps {
        dir('kijanikiosk-payments') {
          withCredentials([usernamePassword(
            credentialsId: 'nexus-credentials',
            usernameVariable: 'NEXUS_USER',
            passwordVariable: 'NEXUS_PASS'
          )]) {
            sh '''
              ENCODED=$(echo -n "${NEXUS_USER}:${NEXUS_PASS}" | base64)
              echo "registry=${NEXUS_URL}/repository/${NEXUS_REPO}/" > .npmrc
              echo "//localhost:8081/repository/${NEXUS_REPO}/:_auth=${ENCODED}" >> .npmrc
              echo "email=ci@kijanikiosk.com" >> .npmrc
              npm version ${APP_VERSION} --no-git-tag-version --allow-same-version
              npm publish --registry ${NEXUS_URL}/repository/${NEXUS_REPO}/
              rm -f .npmrc
            '''
          }
        }
      }
    }

    stage('Results') {
      steps {
        junit allowEmptyResults: true,
              testResults: 'kijanikiosk-payments/test-results/junit.xml'
      }
    }
  }

  post {
    always {
      cleanWs()
    }
    success {
      echo "SUCCESS — ${APP_NAME}@${APP_VERSION} published to Nexus."
    }
    failure {
      echo "FAILED on stage: ${env.STAGE_NAME}. Build log: ${env.BUILD_URL}console"
    }
    changed {
      echo "Pipeline status changed to ${currentBuild.currentResult} on build #${env.BUILD_NUMBER}"
    }
  }
}