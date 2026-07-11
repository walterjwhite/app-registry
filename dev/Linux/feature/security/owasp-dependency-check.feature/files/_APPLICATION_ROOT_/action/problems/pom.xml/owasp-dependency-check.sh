#!/bin/sh
_APPLICATION_NAME=dev
_NO_EXEC=1
mvn org.owasp:dependency-check-maven:check
