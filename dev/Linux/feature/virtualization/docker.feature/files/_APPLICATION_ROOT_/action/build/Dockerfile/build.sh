#!/bin/sh
_APPLICATION_NAME=dev
_NO_EXEC=1
_DOCKERFILE_PATH=$PWD/.docker/Dockerfile
_DOCKER_APPLICATION_NAME=$(basename $PWD)
find . -type f -name '*.go' -print -quit | grep -cqm1 . && {
	_WARN "Detected go files, switching to repo root"
	_WARN "[ENSURE FILES USING THE COPY CMD ARE RELATIVE TO REPO ROOT]"
	_PROJECT_ROOT=$(git rev-parse --show-toplevel)
	cd $_PROJECT_ROOT
}
docker build -f $_DOCKERFILE_PATH -t $_DOCKER_APPLICATION_NAME .
