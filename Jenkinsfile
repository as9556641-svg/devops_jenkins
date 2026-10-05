pipeline {
    agent any
    options {
        skipDefaultCheckout(true)
        timestamps()
    }
    parameters {
        string(name: 'NOTIFICATION_EMAIL', defaultValue: '', description: 'Optional recipient for build notifications (requires Email Extension plugin and SMTP configuration).')
    }
    environment {
        APP_NAME = 'flask-ci-cd'
        APP_PORT = '5000'
        IMAGE_NAME = 'flask-ci-cd'
        IMAGE_TAG = "${BUILD_NUMBER}"
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Test') {
            steps {
                sh '''
                    python3 -m venv .venv
                    .venv/bin/python -m pip install --upgrade pip
                    .venv/bin/python -m pip install -r requirements.txt
                    .venv/bin/python -m pytest -q
                '''
            }
        }
        stage('Build') {
            steps {
                sh 'docker build --pull -t "$IMAGE_NAME:$IMAGE_TAG" .'
            }
        }
        stage('Deploy') {
            steps {
                sh '''
                    running_on_port="$(docker ps -q --filter "publish=${APP_PORT}")"
                    if [ -n "$running_on_port" ]; then
                        docker rm -f $running_on_port
                    fi

                    docker rm -f "$APP_NAME" >/dev/null 2>&1 || true
                    docker run -d --restart unless-stopped \
                        --name "$APP_NAME" \
                        --publish "${APP_PORT}:5000" \
                        "$IMAGE_NAME:$IMAGE_TAG"

                    attempt=0
                    until [ "$(docker inspect --format='{{.State.Health.Status}}' "$APP_NAME" 2>/dev/null || true)" = 'healthy' ]; do
                        attempt=$((attempt + 1))
                        if [ "$attempt" -ge 30 ]; then
                            docker logs "$APP_NAME"
                            exit 1
                        fi
                        sleep 2
                    done
                '''
            }
        }
    }
    post {
        success {
            echo 'Pipeline succeeded: application deployed and healthy.'
            script {
                if (params.NOTIFICATION_EMAIL?.trim()) {
                    emailext(
                        to: params.NOTIFICATION_EMAIL,
                        subject: "SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                        body: "Build ${env.BUILD_URL} succeeded. The application is healthy at port ${env.APP_PORT}."
                    )
                }
            }
        }
        failure {
            echo 'Pipeline failed. Review the stage logs for details.'
            script {
                if (params.NOTIFICATION_EMAIL?.trim()) {
                    emailext(
                        to: params.NOTIFICATION_EMAIL,
                        subject: "FAILURE: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                        body: "Build ${env.BUILD_URL} failed. Review the Jenkins console output for details."
                    )
                }
            }
        }
    }
}