#####
#
# Variables
#
#####

#
# What is your app called? This is used to populate some values around the
# building and versioning containers.
#
APP_NAME ?= 

#
# The default environment we are running in.
#
APP_ENV ?= development

#
# The name of the container we need to use to run our build inside of.
# Please not that this currently MUST have docker installed in it so
# you cannot use most stock off the shelf build containers.
#
BUILD_CONTAINER ?= 

#
# Set our AWS Account ID.
#
AWS_ACCOUNT_ID ?= 

#
# The name of our AWS account. Used to reference the ECS cluster we are deploying to.
#
AWS_ACCOUNT_NAME ?= 

#
# Profile to use for AWS commands
#
AWS_PROFILE ?= 

#
# The name of the ECS cluster we are deploying to
#
AWS_ECS_CLUSTER_NAME ?= $(AWS_ACCOUNT_NAME)-$(APP_ENV)

#
# The destination repo for the container when we are done building.
#
DOCKER_REPO ?= $(AWS_ACCOUNT_ID).dkr.ecr.us-east-1.amazonaws.com

#
# The build directory in the container. This is where where the source will be
# mounted in the container and should also be our workdir when we build.
#
BUILD_DIR = /opt/app/$(APP_NAME)

#
# The version our current build should be tagged as in the destination container
# This is normally set by the build server and is defaulted to latest to make it
# easy to test locally. You generally shouldn't change this.
#
BUILD_VERSION ?= latest

#
# The name of the image we are building. Usually this will match the app name but
# sometimes you might need to change this. Be aware that this effects a LOT of things
# and it is likely to break a bunch of the stock deployment options.
#
IMAGE_NAME ?= $(APP_NAME)

#
# Number of times to poll for the service restart
#
AWS_ECS_POLL_COUNT = 60

#
# Flags that are passed to docker on all build/clean operations. This is a great path
# to set language specific things like NODE_ENV and GOPATH for these containers
#
# DOCKER_FLAGS =
