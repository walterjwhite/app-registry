#!/bin/sh
log_info "packaging and deploying artifacts"
mvn clean deploy -DstagingProfileId=$conf_dev_deploy_staging_profile_id $conf_dev_publish_options $@
