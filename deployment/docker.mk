#######
#
# Docker build related targets
#
# You shouldn't need to edit any tasks below here for most situations.
#
#######

# docker
# docker-compose

DOCKER_SOCKET_MAPPING = -v /var/run/docker.sock:/var/run/docker.sock

#
# Create our final build container. This should build and tag the latest version
# of the container that is ready to be rolled to staging/production.
#
# Generally speaking you are going to want a dockerfile for this process to run
# against. For now I suggest you use 'Dockerfile.build' as the file name.
#
docker-release:
	echo "Bulding image for $(APP_NAME) version $(BUILD_VERSION)"
	docker build -t $(DOCKER_REPO)/$(IMAGE_NAME):$(BUILD_VERSION) -f ./Dockerfile.release .

#
# This is generally the make command that the build server will run. Kick off
# all of our deployment build in docker. This is responsible for starting
# the build container, mapping in the data and other directories, and executing
# the `make deployment` command.
#
docker-deployment:
	echo "Compiling for $(APP_NAME) version $(BUILD_VERSION)"

	docker run \
		--rm -i \
		-v $(PWD):$(BUILD_DIR) \
		-w $(BUILD_DIR) \
		$(DOCKER_FLAGS) \
		$(BUILD_CONTAINER) \
		make deployment
	
	docker build \
		-t $(DOCKER_REPO)/$(IMAGE_NAME):$(BUILD_VERSION) \
		-f ./Dockerfile.release \
		.

#
# Clean up things inside the build container. This is useful on a build server
# where the container runs as root but the build system does not. This allows
# the contiainer to clean up the source path so that the build system is able
# to delete it and clean up after itself.
#
docker-clean:
	docker run \
		--rm -i \
		-v $(PWD):$(BUILD_DIR) \
		-w $(BUILD_DIR) \
		$(DOCKER_FLAGS) \
		$(BUILD_CONTAINER) \
		make clean

#
# Run the build contiainer with everything mapped in and give the user a shell
# prompt. Very useful for debugging build issues both locally and on the build
# server.
#
docker-shell:
	docker run \
		--rm -it \
		-v $(PWD):$(BUILD_DIR) \
		-w $(BUILD_DIR) \
		$(DOCKER_FLAGS) \
		$(BUILD_CONTAINER) \
		/bin/bash

