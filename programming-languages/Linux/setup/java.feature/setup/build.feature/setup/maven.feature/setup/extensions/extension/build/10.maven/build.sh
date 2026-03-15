#!/bin/sh
: ${conf_dev_maven_default_log_level:=warn}
: ${conf_dev_maven_file_transfer_log_level:=warn}
[ -z "$interactive" ] && {
	optn_dev_maven_batch="-B"
}
: ${conf_dev_maven_options:="-Dorg.slf4j.simpleLogger.defaultLogLevel=$conf_dev_maven_default_log_level \
    -Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=$conf_dev_maven_file_transfer_log_level \
    -ntp -q $optn_dev_maven_batch"}
: ${conf_dev_maven_dependency_version:=use-latest-releases}
_maven_run_build() {
  mvn clean install $conf_dev_maven_options "$@" 2>&1
}
[ -e pom.xml ] && {
  _maven_run_build "$@"
  return
}
maven_err_count=0
maven_opwd=$PWD
for _MAVEN_PROJECT_DIR in $(extension_find_dirs_containing); do
  cd $_MAVEN_PROJECT_DIR
  _maven_run_build "$@" || {
    maven_err_count=$(($maven_err_count + 1))
  }
  cd $maven_opwd
done
return $maven_err_count
