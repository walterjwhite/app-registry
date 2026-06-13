#!/bin/sh
_APPLICATION_NAME=dev
_INFO "Attempting to update dependencies"
mvn versions:use-latest-releases $_CONF_DEV_MAVEN_OPTIONS && gc -am 'updated dependencies' && gpush
