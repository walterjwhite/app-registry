#!/bin/sh
_APPLICATION_NAME=dev
_RUN_DOCKERFILE_INIT() {
	[ -n "$CONTAINER_PORT" ] && [ -n "$HOST_PORT" ] && {
		_DETAIL "exposing $CONTAINER_PORT -> $HOST_PORT"
		DOCKER_ARGS="$DOCKER_ARGS -p$HOST_PORT:$CONTAINER_PORT"
	}
	_DOCKERFILE_PATH=$PWD/.docker/Dockerfile
	_DOCKER_APPLICATION_NAME=$(basename $PWD)
	_docker_env
	_docker_secrets
}
_docker_env() {
	_DOCKER_ENV_VARS=""
	local env_key env_value
	for env_key in $($_CONF_GNU_GREP -Pv '(^$|^#)' .application/.env | sed -e 's/=.*$//'); do
		env_value=$(env | $_CONF_GNU_GREP -P "^$env_key=.*$" | sed -e 's/^.*=//')
		_DOCKER_ENV_VARS="$_DOCKER_ENV_VARS -e $env_key='$env_value'"
	done
}
_docker_secrets() {
	local secret_key secret_value
	for secret_key in $($_CONF_GNU_GREP -Pv '(^$|^#)' .application/.secrets | sed -e 's/=.*$//'); do
		secret_value=$(env | $_CONF_GNU_GREP -P "^$secret_key=.*$" | sed -e 's/^.*=//')
		_DOCKER_ENV_VARS="$_DOCKER_ENV_VARS -e $secret_key='$secret_value'"
	done
}
_RUN_DOCKERFILE() {
	eval "docker run -it --rm $DOCKER_ARGS $_DOCKER_ENV_VARS --name ${_DOCKER_APPLICATION_NAME}-running $_DOCKER_APPLICATION_NAME"
}
