pipeline {
    agent any
    tools {
        nodejs 'NodeJS v26'
    }

    stages {
        stage('Environment Check') {
            steps {
                sh 'echo "Build triggered for: $(git log -1 --pretty=%s)"'
                sh 'node --version'
                sh 'this-command-does-not-exist'
                sh 'npm --version'
            }
        }
    }

    post {
        always {
            echo "Pipeline finished. Status: ${currentBuild.result ?: 'SUCCESS'}"
        }
    }
}
