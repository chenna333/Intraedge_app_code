pipeline {
    agent any

    environment {
        // Set environment variables
        APP_NAME = "intraedge-app"
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        ECR_REPO = "<your-aws-account-id>.dkr.ecr.<region>.amazonaws.com/intraedge-app"
        KUBE_NAMESPACE = "staging"  // change to production if needed
        HELM_RELEASE = "intraedge-app"
        SONARQUBE_SERVER = "SonarQubeServer"  // Jenkins SonarQube config name
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/chenna333/Intraedge_app_code.git'
            }
        }

        stage('SonarQube Scan') {
            steps {
                withSonarQubeEnv("${SONARQUBE_SERVER}") {
                    sh """
                    # Example for Maven
                    mvn clean verify sonar:sonar \
                      -Dsonar.projectKey=${APP_NAME} \
                      -Dsonar.host.url=$SONAR_HOST_URL \
                      -Dsonar.login=$SONAR_AUTH_TOKEN
                    """
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                docker build -t ${APP_NAME}:${IMAGE_TAG} ./application
                docker tag ${APP_NAME}:${IMAGE_TAG} ${ECR_REPO}:${IMAGE_TAG}
                """
            }
        }

        stage('Trivy Scan') {
            steps {
                sh """
                if ! command -v trivy &> /dev/null
                then
                    curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh
                fi

                trivy image --exit-code 1 --severity HIGH,CRITICAL ${ECR_REPO}:${IMAGE_TAG}
                """
            }
        }

        stage('Push to ECR') {
            steps {
                withAWS(region:'<region>', credentials:'<aws-credentials-id>') {
                    sh """
                    aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin ${ECR_REPO}
                    docker push ${ECR_REPO}:${IMAGE_TAG}
                    """
                }
            }
        }

        stage('Deploy Helm Chart to EKS') {
            steps {
                sh """
                # Update Helm dependencies
                helm dependency update ./kubernetes/helm-chart

                # Upgrade or install with atomic rollback
                helm upgrade --install ${HELM_RELEASE} ./kubernetes/helm-chart \
                  --namespace ${KUBE_NAMESPACE} \
                  --set image.repository=${ECR_REPO} \
                  --set image.tag=${IMAGE_TAG} \
                  --atomic --timeout 5m
                """
            }
        }

    }

    post {
        failure {
            echo "Pipeline failed! Check logs and SonarQube / Trivy reports."
        }
        success {
            echo "Deployment successful: ${APP_NAME}:${IMAGE_TAG} deployed to ${KUBE_NAMESPACE}"
        }
    }
}
