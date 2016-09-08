
node() {

  stage 'Setting up our environment'

  // set the BUILD_VERSION based on the Jenkins BUILD_NUMBER
  env.BUILD_VERSION = "v${env.BUILD_NUMBER}"
  env.APP_NAME = ""
  env.APP_ENV = "development"
  env.BUILD_CONTAINER = ""
  env.AWS_ACCOUNT_ID = ""
  env.AWS_ACCOUNT_NAME = ""
  env.AWS_PROFILE = ""
  env.DOCKER_REPO = "${env.AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com"
  env.BUILD_DIR = ""
  env.IMAGE_NAME = ""

  // set some stuff that needs to get passed in to the build container
  env.DOCKER_ARGS = "-e BUILD_VERSION=${env.BUILD_VERSION} -e IMAGE_NAME=${env.IMAGE_NAME}"

  sh 'env'


  //----------
  stage 'Checking for clean'
  if (fileExists('Makefile')) {
    echo 'Found Makefile, cleaning'
    sh 'make docker-clean'
  } else {
    echo 'No Makefile, skipping clean'
  }


  //----------
  stage 'Checking out source code'
  checkout scm


  //----------
  stage 'Making deployment build'
  sh 'make docker-release'


  //----------
  stage 'Pushing to ECR'
  sh 'make aws-ecr-auth'
  sh 'make aws-ecr-push'


  //----------
  stage 'Deploy app'
  
  switch (env.BRANCH_NAME) {
    case "staging":
      env.APP_ENV = "staging"
      sh 'make aws-ecs-task-create'
      sh 'make aws-ecs-service-update'
      sh 'make aws-ecs-service-status-poll'
      sh 'make aws-ecs-service-stable'
      break

    case "master":
      env.APP_ENV = "production"
      sh 'make aws-ecs-task-create'
      sh 'make aws-ecs-service-update'
      sh 'make aws-ecs-service-status-poll'
      sh 'make aws-ecs-service-stable'
      break

    default:
      echo "Skipping deployment, branch ${env.BRANCH_NAME} not configured."
  }
}
