#####
#
# AWS related targets
#
#####

# envsubst
# jq

#
# Authenticate to the ECR repo for push/pull operations
#
aws-ecr-auth:
	`aws ecr get-login --region us-east-1 --registry-ids ${AWS_ACCOUNT_ID}`

#
# Push our versioned images up to ECR.
# Also tag our version as latest and update it in ECR.
#
aws-ecr-push:
	docker push $(DOCKER_REPO)/$(IMAGE_NAME):$(BUILD_VERSION)
	docker tag $(DOCKER_REPO)/$(IMAGE_NAME):$(BUILD_VERSION) $(DOCKER_REPO)/$(IMAGE_NAME):latest
	docker push $(DOCKER_REPO)/$(IMAGE_NAME):latest

#
# Generate our ECS template based on ALL of the environment variables we
# have available INCLUDING the variables set in the Makefile(s) associated
# with this build.
#
.EXPORT_ALL_VARIABLES:
aws-ecs-task-template:

	@echo "Parsing ECS template"
	@env
	envsubst < deployment/ecs_template.json | \
		tee deployment/ecs_template_$(APP_ENV).json \
		; exit "$${PIPESTATUS[0]}"


#
# Generate our task definition for the current environment and then create an
# updated task definition in ECS.
#
aws-ecs-task-create: aws-ecs-task-template
	@echo "Creating ECS Task from populated template"
	aws ecs \
		--profile=$(AWS_PROFILE) \
		register-task-definition \
		--family $(APP_NAME)-$(APP_ENV) \
		--cli-input-json file://deployment/ecs_template_$(APP_ENV).json \
		| tee deployment/ecs_task_$(APP_ENV).json ; exit "$${PIPESTATUS[0]}"


#
# Update our service to the current task version. This will trigger a new deploy
# in ECS.
#
aws-ecs-service-update:

	$(eval ECS_TASK_VERSION=0)

ifneq (,$(wildcard deployment/ecs_task_$(APP_ENV).json))
	@echo "Loading task version from task update json"
	$(eval ECS_TASK_VERSION = $(shell jq '.taskDefinition.revision' deployment/ecs_task_$(APP_ENV).json))
	@echo "Found task version: $(ECS_TASK_VERSION)"
endif

ifdef VERSION
	@echo "Updating to task version from VERSION to $(VERSION)"
	$(eval ECS_TASK_VERSION = $(VERSION))
	@echo "Found task version: $(ECS_TASK_VERSION)"
endif

	if [ $(ECS_TASK_VERSION) -eq 0 ]; then exit 42; fi
	@echo "Task Revision: $(ECS_TASK_VERSION)"
	aws ecs \
		--profile=$(AWS_PROFILE) \
		update-service \
		--cluster=$(AWS_ECS_CLUSTER_NAME) \
		--service $(APP_NAME) \
		--desired-count 2 \
		--task-definition $(APP_NAME)-$(APP_ENV):$(ECS_TASK_VERSION) \
		--deployment-configuration maximumPercent=200,minimumHealthyPercent=50 \
		| tee deployment/ecs_service_update.json \
		; exit "$${PIPESTATUS[0]}"


#
# Get that status of our service from ECS and store it in a file called
# ecs_service_status.json
#
aws-ecs-service-status:
	aws ecs \
		--profile=$(AWS_PROFILE) describe-services \
		--cluster=$(AWS_ECS_CLUSTER_NAME) \
		--service $(APP_NAME) \
		> deployment/ecs_service_status.json

#
# Poll the ECS service and output the deployments and the last 5 log
# messages. This updates the ecs_service_status.json file.
#
aws-ecs-service-status-poll:
	@n=$(AWS_ECS_POLL_COUNT); \
	while [ $${n} -gt 0 ] ; do \
		echo "Updating service status at $${n}"; \
		aws ecs \
			--profile=$(AWS_PROFILE) describe-services \
			--cluster=$(AWS_ECS_CLUSTER_NAME) \
			--service $(APP_NAME) \
			> deployment/ecs_service_status.json; \
		jq '.services[0].deployments[],.services[0].events[0,1,2,3,4]' deployment/ecs_service_status.json; \
		\
		n=`expr $$n - 1`; \
		sleep 5; \
	done; \
	true

#
# Check and see if the service is stable. This calls the status target
# to update the ecs_service_status.json file. It then compares desired
# container count to running container count to see if they match. exit
# with code of 0 if they do match, 1 if they do not.
#
aws-ecs-service-stable: aws-ecs-service-status
aws-ecs-service-stable:
	$(DESIRED=`jq '.services[0].deployments[0].desiredCount' deployment/ecs_service_status.json`)
	$(RUNNING=`jq '.services[0].deployments[0].runningCount' deployment/ecs_service_status.json`)

	@echo "Desired container count: $(DESIRED)"; \
	echo "Running container count: $(RUNNING)"; \
	if [ $(DESIRED) -eq $(RUNNING) ]; then echo "Deploy successful!"; exit 0; else echo "Deploy failed!"; exit 1; fi
