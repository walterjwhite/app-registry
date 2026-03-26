#!/bin/sh
: ${conf_dev_google_cloud_cli_registry:=gcr.io}
: ${conf_dev_google_cloud_cli_platform:=managed}
: ${conf_dev_google_cloud_cli_region:=us-east1}
_runner_init() {
  gcloud auth list 2>&1 | grep -cqm1 'No credentialed accounts.' && {
    log_warn "google cloud login"
    gcloud auth login
  }
  _gcloud_env
  _gcloud_secrets
  DEV_GOOGLE_CLOUD_PROJECT_ID=$(secrets -out=stdout get $DEV_GOOGLE_CLOUD_PROJECT_ID)
  gcloud config set project $DEV_GOOGLE_CLOUD_PROJECT_ID
}
_runner_run() {
  PROJECT_NAME=$(basename $PWD)
  case $APPLICATION_TYPE in
  docker)
    docker tag $PROJECT_NAME:latest $conf_dev_google_cloud_cli_registry/$DEV_GOOGLE_CLOUD_PROJECT_ID/$PROJECT_NAME:latest
    gcloud auth configure-docker
    docker push $conf_dev_google_cloud_cli_registry/$DEV_GOOGLE_CLOUD_PROJECT_ID/$PROJECT_NAME:latest
    eval "gcloud run deploy $PROJECT_NAME \
                --image=$conf_dev_google_cloud_cli_registry/$DEV_GOOGLE_CLOUD_PROJECT_ID/$PROJECT_NAME:latest \
                --min-instances=0 \
                $_gcloud_env_vars \
                --region=$conf_dev_google_cloud_cli_region \
                --project=$DEV_GOOGLE_CLOUD_PROJECT_ID" &&
      gcloud run services update-traffic $PROJECT_NAME --region=$conf_dev_google_cloud_cli_region --to-latest
    ;;
  *)
    exit_with_error "unsupported application type: $APPLICATION_TYPE"
    ;;
  esac
}
_gcloud_env() {
  _gcloud_env_vars=""
  local env_key env_value
  for env_key in $($GNU_GREP -Pv '(^$|^#)' .run/.env | sed -e 's/=.*$//'); do
    env_value=$(env | $GNU_GREP -P "^$env_key=.*$" | sed -e 's/^.*=//')
    _gcloud_env_vars="$_gcloud_env_vars --set-env-vars=$env_key='$env_value'"
  done
}
_gcloud_secrets() {
  local secret_key secret_value
  for secret_key in $($GNU_GREP -Pv '(^$|^#)' .run/.secrets | sed -e 's/=.*$//'); do
    secret_value=$(env | $GNU_GREP -P "^$secret_key=.*$" | sed -e 's/^.*=//')
    _gcloud_env_vars="$_gcloud_env_vars --set-env-vars=$secret_key='$secret_value'"
  done
}
