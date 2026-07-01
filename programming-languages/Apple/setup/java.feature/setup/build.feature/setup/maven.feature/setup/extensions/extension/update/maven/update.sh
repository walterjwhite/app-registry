#!/bin/sh
log_info "attempting to update dependencies"
mvn versions:use-latest-releases $conf_dev_maven_options && gcommit -am 'updated dependencies' && gpush
