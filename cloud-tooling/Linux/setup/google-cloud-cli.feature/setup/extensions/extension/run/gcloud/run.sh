#!/bin/sh
: ${conf_dev_google_cloud_cli_registry:=gcr.io}
: ${conf_dev_google_cloud_cli_platform:=managed}
: ${conf_dev_google_cloud_cli_region:=us-east1}
_runner_init() {
  gcloud auth list 2>&1 | grep -cqm1 'No credentialed accounts.' && {
    log_warn "google cloud login"
    gcloud auth login
  }
  _gcloud_secrets
  _gcloud_env
  DEV_GOOGLE_CLOUD_PROJECT_ID=$(secrets -out=stdout get $DEV_GOOGLE_CLOUD_PROJECT_ID)
  gcloud config set project $DEV_GOOGLE_CLOUD_PROJECT_ID
}
_runner_run() {
  case $APPLICATION_TYPE in
  docker | podman)
    ;;
  *)
    exit_with_error "unsupported application type: $APPLICATION_TYPE"
    ;;
  esac
  PROJECT_NAME=$(basename $PWD)
  gcloud auth configure-docker
  case $APPLICATION_TYPE in
  docker)
    docker tag $PROJECT_NAME:latest $conf_dev_google_cloud_cli_registry/$DEV_GOOGLE_CLOUD_PROJECT_ID/$PROJECT_NAME:latest
    docker push $conf_dev_google_cloud_cli_registry/$DEV_GOOGLE_CLOUD_PROJECT_ID/$PROJECT_NAME:latest
    ;;
  podman)
    podman tag $PROJECT_NAME:latest $conf_dev_google_cloud_cli_registry/$DEV_GOOGLE_CLOUD_PROJECT_ID/$PROJECT_NAME:latest
    podman push $conf_dev_google_cloud_cli_registry/$DEV_GOOGLE_CLOUD_PROJECT_ID/$PROJECT_NAME:latest
    ;;
  esac
  eval "gcloud run deploy $PROJECT_NAME \
    --image=$conf_dev_google_cloud_cli_registry/$DEV_GOOGLE_CLOUD_PROJECT_ID/$PROJECT_NAME:latest \
    --min-instances=0 \
    $_gcloud_env_vars \
    --region=$conf_dev_google_cloud_cli_region \
    --project=$DEV_GOOGLE_CLOUD_PROJECT_ID" &&
    gcloud run services update-traffic $PROJECT_NAME --region=$conf_dev_google_cloud_cli_region --to-latest
}
_gcloud_env() {
  local env_key env_value
  for env_key in $($GNU_GREP -Pv '(^$|^#)' .run/.env | sed -e 's/=.*$//'); do
    env_value=$(env | $GNU_GREP -P "^$env_key=.*$" | sed -e 's/^[^=]*=//')
    [ -z "$env_value" ] && continue
    _gcloud_env_vars="$_gcloud_env_vars --set-env-vars=$env_key='$env_value'"
  done
}
_gcloud_secrets() {
  local secret_key secret_value
  for secret_key in $($GNU_GREP -Pv '(^$|^#)' .run/.secrets | sed -e 's/=.*$//'); do
    secret_value=$(env | $GNU_GREP -P "^$secret_key=.*$" | sed -e 's/^[^=]*=//')
    [ -z "$secret_value" ] && continue
    _gcloud_env_vars="$_gcloud_env_vars --set-env-vars=$secret_key='$secret_value'"
  done
  local secret_files
  for secret_key in $($GNU_GREP -Pv '(^$|^#)' .run/secret-files | cut -f1 -d'='); do
    secret_value=$($GNU_GREP -P "^${secret_key}=" .run/secret-files | cut -d'=' -f2-)
    local secret_path_in_container=$(env | $GNU_GREP -P "^$secret_key=.*$" | sed -e 's/^[^=]*=//')
    [ -z "$secret_path_in_container" ] && {
      log_warn "secret_path_in_container is empty"
      continue
    }
    google_cloud_secret_name="${secret_key}_RAW"
    if [ -n "$secret_files" ]; then
      secret_files="$secret_files,$secret_path_in_container=$google_cloud_secret_name:latest"
    else
      secret_files="$secret_path_in_container=$google_cloud_secret_name:latest"
    fi
    _gcloud_create_secret "$secret_value"
    unset google_cloud_secret_name
  done
  if [ -n "$secret_files" ]; then
    _gcloud_env_vars="$_gcloud_env_vars --set-secrets=$secret_files"
  fi
}
_gcloud_create_secret() {
  validation_require "$google_cloud_secret_accessor" google_cloud_secret_accessor
  _gcloud_secret_exists && {
    log_debug "$google_cloud_secret_name already exists"
    return
  }
  log_info "creating $google_cloud_secret_name"
  gcloud secrets create "$google_cloud_secret_name" --data-file="$1" || log_warn "failed to create $google_cloud_secret_name"
  gcloud secrets add-iam-policy-binding "$google_cloud_secret_name" \
    --member="serviceAccount:$google_cloud_secret_accessor" \
    --role="roles/secretmanager.secretAccessor" || log_warn "failed to assign access: $google_cloud_secret_name"
}
_gcloud_secret_exists() {
  gcloud secrets describe "$google_cloud_secret_name" >/dev/null 2>&1
}
