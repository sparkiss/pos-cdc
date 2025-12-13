pipeline {
    agent any

    environment {
        GO_VERSION = '1.25.5'
        GOPATH = "${WORKSPACE}/go"
        PATH = "${GOPATH}/bin:/usr/local/go/bin:${PATH}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Setup Go') {
            steps {
                sh '''
                    # Download and install Go if not present
                    if ! command -v go &> /dev/null || [[ $(go version) != *"${GO_VERSION}"* ]]; then
                        curl -LO https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz
                        sudo rm -rf /usr/local/go
                        sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
                        rm go${GO_VERSION}.linux-amd64.tar.gz
                    fi
                    go version
                '''
            }
        }

        stage('Download Dependencies') {
            steps {
                sh 'go mod download'
            }
        }

        stage('Test') {
            steps {
                sh 'go test -v -race -coverprofile=coverage.txt -covermode=atomic ./...'
            }
            post {
                always {
                    // Archive coverage report
                    archiveArtifacts artifacts: 'coverage.txt', allowEmptyArchive: true
                }
            }
        }

        stage('Lint') {
            steps {
                sh '''
                    # Install golangci-lint if not present
                    if ! command -v golangci-lint &> /dev/null; then
                        curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v1.55.2
                    fi
                    golangci-lint run --timeout=5m
                '''
            }
        }

        stage('Security Scan') {
            steps {
                sh '''
                    # Install gosec if not present
                    if ! command -v gosec &> /dev/null; then
                        go install github.com/securego/gosec/v2/cmd/gosec@latest
                    fi
                    gosec ./...
                '''
            }
        }
    }

    post {
        success {
            zulipSend(
                    stream: 'pos-cdc-ci',
                    topic: 'pos-cdc',
                    message: "✅ CI Passed ${env.JOB_NAME} #${env.BUILD_NUMBER}"
                    )
            build job: 'pos-cdc-build', wait: false
        }
        failure {
            zulipSend(
                    stream: 'pos-cdc-ci',
                    topic: 'pos-cdc',
                    message: "❌ CI FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}\nURL: ${env.BUILD_URL}"
                    )
        }
    }
}

