pipeline {
    agent none  // No default agent - use Docker per stage

    environment {
        GO_VERSION = '1.25'
    }

    stages {
        stage('Checkout') {
            agent any
            steps {
                zulipSend(
                    stream: 'Jenkins',
                    topic: 'pos-cdc',
                    message: "🚀 CI Started: ${env.JOB_NAME} #${env.BUILD_NUMBER}\nURL: ${env.BUILD_URL}"
                )
                checkout scm
            }
        }

        stage('Test') {
            agent {
                docker {
                    image "golang:${GO_VERSION}"
                    args '-u root:root'
                }
            }
            steps {
                checkout scm
                sh 'go mod download'
                sh 'go test -v -race -coverprofile=coverage.txt -covermode=atomic ./...'
            }
            post {
                always {
                    archiveArtifacts artifacts: 'coverage.txt', allowEmptyArchive: true
                }
            }
        }

        stage('Lint & Security') {
            agent {
                docker {
                    image 'golangci/golangci-lint:latest'
                    args '-u root:root'
                }
            }
            steps {
                checkout scm
                sh 'golangci-lint run --timeout=5m'
            }
        }
    }

    post {
        success {
            node('built-in') {
                zulipSend(
                    stream: 'Jenkins',
                    topic: 'pos-cdc',
                    message: "✅ CI PASSED ${env.JOB_NAME} #${env.BUILD_NUMBER}\nURL: ${env.BUILD_URL}"
                )
                build job: 'pos-cdc-build', wait: false
            }
        }
        failure {
            node('built-in') {
                zulipSend(
                    stream: 'Jenkins',
                    topic: 'pos-cdc',
                    message: "❌ CI FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}\nURL: ${env.BUILD_URL}"
                )
            }
        }
    }
}
