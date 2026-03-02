#!/bin/sh
local project_id=$(mvn -q -Dexec.executable=echo -Dexec.args='${project.groupId}/${project.artifactId}' --non-recursive exec:exec 2>/dev/null | sed -e "s/\./\//g")
rm -ri ~/.m2/repository/$project_id
