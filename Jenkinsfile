pipeline {
    agent any

    environment {
        GOOGLE_APPLICATION_CREDENTIALS = credentials('gcp-service-account')  // Secret file
        GOOGLE_CLOUD_PROJECT           = credentials('gcp-project-id')       // Secret text
        REGION                         = 'us-central1'
        REPO_NAME                      = 'docker-repo'
        SERVICE_NAME                   = 'flaskapp'
        IMAGE_NAME                     = 'flaskapp'
        IMAGE_TAG                      = "1.0.${env.BUILD_NUMBER}"
        IMAGE_URI                      = "us-central1-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/${REPO_NAME}/${IMAGE_NAME}"
    }

    stages {

        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Git Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/vijaygiduthuri/flaskapp.git'
            }
        }

        stage('Authenticate with Google Cloud') {
            steps {
                sh '''
                    gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS
                    gcloud config set project $GOOGLE_CLOUD_PROJECT
                    gcloud config set run/region $REGION
                    gcloud auth configure-docker us-central1-docker.pkg.dev
                '''
            }
        }

        stage('Build, Tag & Push Docker Image to Artifact Registry') {
            steps {
                sh '''
                    docker build -t $IMAGE_NAME:latest .
                    docker tag $IMAGE_NAME:latest $IMAGE_URI:$IMAGE_TAG
                    docker tag $IMAGE_NAME:latest $IMAGE_URI:latest
                    docker push $IMAGE_URI:$IMAGE_TAG
                    docker push $IMAGE_URI:latest
                '''
            }
        }

        stage('Scan Docker Image using Trivy') {
            steps {
                sh '''
                    echo "Scanning image: $IMAGE_URI:$IMAGE_TAG"
                    trivy image $IMAGE_URI:$IMAGE_TAG
                '''
            }
        }

        stage('Terraform Init & Plan') {
            steps {
                dir('terraform') {
                    sh '''
                        terraform init
                        terraform plan \
                          -var="project_id=$GOOGLE_CLOUD_PROJECT" \
                          -var="region=$REGION" \
                          -var="service_name=$SERVICE_NAME" \
                          -var="container_image=$IMAGE_URI:latest"
                    '''
                }
            }
        }

        stage('Provision Cloud Run if Not Exists') {
            steps {
                dir('terraform') {
                    script {
                        def exists = sh(
                            script: "gcloud run services describe $SERVICE_NAME --region=$REGION --project=$GOOGLE_CLOUD_PROJECT > /dev/null 2>&1 || echo 'NOT_FOUND'",
                            returnStdout: true
                        ).trim()

                        if (exists == 'NOT_FOUND') {
                            echo "Cloud Run service does not exist. Creating..."
                            sh '''
                                terraform apply -auto-approve \
                                  -var="project_id=$GOOGLE_CLOUD_PROJECT" \
                                  -var="region=$REGION" \
                                  -var="service_name=$SERVICE_NAME" \
                                  -var="container_image=$IMAGE_URI:latest"
                            '''
                        } else {
                            echo "Cloud Run service already exists. Skipping Terraform apply."
                        }
                    }
                }
            }
        }

        stage('Deploy Latest Image to Cloud Run') {
            steps {
                sh '''
                    gcloud run deploy $SERVICE_NAME \
                      --image=$IMAGE_URI:$IMAGE_TAG \
                      --region=$REGION \
                      --platform=managed \
                      --allow-unauthenticated
                '''
            }
        }
    }

    post {
        always {
            echo "Pipeline execution completed."
        }
    }
}
