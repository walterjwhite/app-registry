#!/bin/sh
mvn org.apache.maven.plugins:maven-enforcer-plugin:enforce -Denforcer.rules=dependencyConvergence
