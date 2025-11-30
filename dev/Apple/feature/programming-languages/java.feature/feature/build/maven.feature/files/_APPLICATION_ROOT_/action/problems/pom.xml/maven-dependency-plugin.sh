#!/bin/sh
_APPLICATION_NAME=dev
_NO_EXEC=1
mvn org.apache.maven.plugins:maven-dependency-plugin:analyze-only $_OPTN_DEV_MAVEN_DEPENDENCY_PLUGIN_OPTIONS
