#!/bin/sh
_runner_init() {
  [ -n "$_CONTAINER_PORT" ] && [ -n "$_HOST_PORT" ] && {
    log_detail "exposing $_CONTAINER_PORT -> $_HOST_PORT"
    docker_args="$docker_args -p$_HOST_PORT:$_CONTAINER_PORT"
  }
  docker_application_name=$(basename $PWD)
  _docker_env
  _docker_secrets
  _docker_secret_files
}
_docker_env() {
  docker_env_vars=""
  local env_key env_value
  for env_key in $($GNU_GREP -Pv '(^$|^#)' .run/.env | sed -e 's/=.*$//'); do
    env_value=$(env | $GNU_GREP -P "^$env_key=.*$" | sed -e 's/^.*=//')
    docker_env_vars="$docker_env_vars -e $env_key='$env_value'"
  done
}
_docker_secret_files() {
  [ ! -e .run/secret-files ] && return 1
  local secret_key secret_file
  for secret_key in $($GNU_GREP -Pv '(^$|^#)' .run/secret-files | cut -f1 -d'='); do
    secret_file=$($GNU_GREP -P "^${secret_key}=" .run/secret-files | cut -f2 -d'=')
    secret_path_in_container=$(env | $GNU_GREP -P "^$secret_key=.*$" | sed -e 's/^.*=//')
    log_debug "processing secret file: $secret_file:$secret_path_in_container:ro,U"
    secret_files="$secret_files -v $secret_file:$secret_path_in_container:ro,U"
  done
}
_docker_secrets() {
  local secret_key secret_value
  for secret_key in $($GNU_GREP -Pv '(^$|^#)' .run/.secrets | sed -e 's/=.*$//'); do
    secret_value=$(env | $GNU_GREP -P "^$secret_key=.*$" | sed -e 's/^.*=//')
    docker_env_vars="$docker_env_vars -e $secret_key='$secret_value'"
  done
}
_runner_run() {
  eval "podman run -it --rm $docker_args $docker_env_vars $secret_files --name ${docker_application_name}-running $docker_application_name"
}
