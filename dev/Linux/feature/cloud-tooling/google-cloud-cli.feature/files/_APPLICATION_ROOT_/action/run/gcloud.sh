#!/bin/sh
_APPLICATION_NAME=dev
_include
: ${_CONF_DEV_GOOGLE_CLOUD_CLI_REGISTRY:=gcr.io}
: ${_CONF_DEV_GOOGLE_CLOUD_CLI_PLATFORM:=managed}
: ${_CONF_DEV_GOOGLE_CLOUD_CLI_REGION:=us-east1}
_RUN_GCLOUD_INIT() {
	gcloud auth list 2>&1 | grep -cqm1 'No credentialed accounts.' && {
		_WARN "google cloud login"
		gcloud auth login
	}
	_gcloud_env
	_gcloud_secrets
	DEV_GOOGLE_CLOUD_PROJECT_ID=$(secrets get -out=stdout $DEV_GOOGLE_CLOUD_PROJECT_ID)
	gcloud config set project $DEV_GOOGLE_CLOUD_PROJECT_ID
}
_RUN_GCLOUD() {
	PROJECT_NAME=$(basename $PWD)
	case $APPLICATION_TYPE in
	docker)
		docker tag $PROJECT_NAME:latest $_CONF_DEV_GOOGLE_CLOUD_CLI_REGISTRY/$DEV_GOOGLE_CLOUD_PROJECT_ID/$PROJECT_NAME:latest
		gcloud auth configure-docker
		docker push $_CONF_DEV_GOOGLE_CLOUD_CLI_REGISTRY/$DEV_GOOGLE_CLOUD_PROJECT_ID/$PROJECT_NAME:latest
		eval "gcloud run deploy $PROJECT_NAME \
                --image=$_CONF_DEV_GOOGLE_CLOUD_CLI_REGISTRY/$DEV_GOOGLE_CLOUD_PROJECT_ID/$PROJECT_NAME:latest \
                --min-instances=0 \
                $_GCLOUD_ENV_VARS \
                --region=$_CONF_DEV_GOOGLE_CLOUD_CLI_REGION \
                --project=$DEV_GOOGLE_CLOUD_PROJECT_ID" &&
			gcloud run services update-traffic $PROJECT_NAME --region=$_CONF_DEV_GOOGLE_CLOUD_CLI_REGION --to-latest
		;;
	*)
		_ERROR "Unsupported application type: $APPLICATION_TYPE"
		;;
	esac
}
_gcloud_env() {
	_GCLOUD_ENV_VARS=""
	local env_key env_value
	for env_key in $($_CONF_GNU_GREP -Pv '(^$|^#)' .application/.env | sed -e 's/=.*$//'); do
		env_value=$(env | $_CONF_GNU_GREP -P "^$env_key=.*$" | sed -e 's/^.*=//')
		_GCLOUD_ENV_VARS="$_GCLOUD_ENV_VARS --set-env-vars=$env_key='$env_value'"
	done
}
_gcloud_secrets() {
	local secret_key secret_value
	for secret_key in $($_CONF_GNU_GREP -Pv '(^$|^#)' .application/.secrets | sed -e 's/=.*$//'); do
		secret_value=$(env | $_CONF_GNU_GREP -P "^$secret_key=.*$" | sed -e 's/^.*=//')
		_GCLOUD_ENV_VARS="$_GCLOUD_ENV_VARS --set-env-vars=$secret_key='$secret_value'"
	done
}
