#!/bin/sh
set -a
_APPLICATION_NAME=dev
_NO_EXEC=1
mvn org.apache.maven.plugins:maven-enforcer-plugin:enforce -Denforcer.rules=dependencyConvergence
