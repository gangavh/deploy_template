# deploy_template
A collection of scripts/makefile/dockerfile to help build and deploy an app on AWS.

## Build Variables
Process wide variables are stored in `deployent/vars.mk`. You need to fill in the blanks before you use
these make targets. Most variables are documented in the vars file.

## Building
Building is done in a container with the source code in the current directly mapped in as a volume.
The actual build is done in the `build` target and can be tested locally (assuming you have all build tools
in place) by running `make build`.

After setting the proper build variables you can also run your build in a container (prefered method). To execute
the build run `make docker-deployment` and the correct commands to fire up your build container, map in the
correct volumes, and execute `make build` inside your container. Since your source code is on a mapped volume
any binaries are created with the container architecture but left in your local filesystem so they can be mapped
in to a deployable container.

Once the artifacts are build, `make docker-deployment` also runs `docker build` pointed at `Dockerfile.release` to 
create the deployable image with the correct artifacts mapped in. This container is also tagged based on the value
set in the `DOCKER_REPO` variable.

## Deploying
Deployments are in a seperate file from builds to allow different deployment methods to be added in. The method currently
available is for Amazon Web Services and ECS and is stored in `deployment/aws.mk`

### AWS Deployment
Deploying to AWS requires the following steps.
	
* Push our image to ECR
* Create an ECS Task definition based on what is found in `deployment/ecs_template.json`
* Update the ECS Service to the new task definition

In addition to these steps there are extra steps to poll the deployment status and validate the deployment status.
The polling/validation are currently very beta and don't properly fail correctly if there are issues.

#### AWS Deployment commands
Ignoring (for now) the variables you want to override/set, here are the command we run to do the deployment.

```
sh 'make aws-ecs-task-create'
sh 'make aws-ecs-service-update'
```

To poll the deployment and validate that it was successful we run these.

```
sh 'make aws-ecs-service-status-poll'
sh 'make aws-ecs-service-stable'
```

## Jenkinsfile
Also provided here is a Jenkinsfile. This can be used to execute a Jenkins build pipepline that does the build
and deployment for you. This is very very rough and should only be used as a starting point for your pipeline adventures.