#!/bin/sh
_APPLICATION_NAME=dev
_PROJECT_ID=$(mvn -q -Dexec.executable=echo -Dexec.args='${project.groupId}/${project.artifactId}' --non-recursive exec:exec 2>/dev/null | sed -e "s/\./\//g")
rm -ri ~/.m2/repository/$_PROJECT_ID
