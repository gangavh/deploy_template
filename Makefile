include deployment/vars.mk
include deployment/docker.mk
include deployment/aws.mk

#
# Give the build a chance to override anything that has already been setup.
# This file should NOT  be included in your repo and is inteded to be added
# at build time to allow the build agent to override any of your variables.
#
ifneq (,$(wildcard deployment/build.mk))
include deployment/build.mk
endif

#####
#
# Default Targets. Please edit these to work properly with your application.
#
#####

#
# Our default target, clean up, do our install, test, and build locally.
#
default: clean install test build

#
# Do our download/install process.
#
install:
	NODE_ENV=production npm install --quiet

#
# Do what we need to do to run our unit tests.
#
test:
	@echo "Must add tests yo!"

#
# Build/compile our application.
#
build:
	@echo "Jacked up and good to go sir!"

#
# Execute the application.
#
run:
	NODE_ENV=$(APP_ENV) node server.js

#
# Clean up after our install and build processes. Should get us back to as
# clean as possible.
#
clean:
	rm -rf node_modules npm-debug.log

#
# Do the bulk of the work to do our deployment container build. This runs inside
# the build container and does the heavy lifting of build/compile, testing, and
# creating the final build container.
#
deployment: clean install test build



.PHONY: install test build clean run deployment
