
node() {

  stage 'Setting up our environment'

  // set the BUILD_VERSION based on the Jenkins BUILD_NUMBER
  env.BUILD_VERSION = ""
  env.APP_NAME = "devopsrobo"
  env.APP_ENV = "hackathondemobranch"
  // env.BUILD_CONTAINER = ""
  env.AWS_ACCOUNT_ID = "322270282324"
  env.AWS_ACCOUNT_NAME = ""
  env.AWS_PROFILE = ""
  env.DOCKER_REPO = "322270282324.dkr.ecr.us-east-1.amazonaws.com"
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
  env.APP_ENV = "staging"
  sh 'make aws-ecs-task-create'
  sh 'make aws-ecs-service-update'
  sh 'make aws-ecs-service-status-poll'
  sh 'make aws-ecs-service-stable'

  

 
}
