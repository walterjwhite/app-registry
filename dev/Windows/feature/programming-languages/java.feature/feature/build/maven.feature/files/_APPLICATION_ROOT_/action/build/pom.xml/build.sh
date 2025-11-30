#!/bin/sh
_APPLICATION_NAME=dev
_NO_EXEC=1
mvn clean install $_CONF_DEV_MAVEN_OPTIONS "$@"
