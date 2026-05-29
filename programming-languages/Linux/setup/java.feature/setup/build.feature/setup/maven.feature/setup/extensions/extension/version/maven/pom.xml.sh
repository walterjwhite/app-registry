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
_maven_has_child_modules() {
  if [ $(find . -type f -name pom.xml -print -quit | wc -l) -gt 1 ]; then
    return 0
  fi
  return 1
}
_maven_cleanup() {
  mvn versions:commit
}
_update_version() {
  mvn versions:set -DnewVersion=$maven_new_version && _update_version_children && _maven_cleanup
}
_update_version_children() {
  _maven_has_child_modules && mvn -N versions:update-child-modules
  return 0
}
_update_dependencies() {
  mvn versions:$conf_dev_maven_dependency_version && mvn versions:update-properties $_OPTN_DEV_VERSION_MAVEN_PROPERTIES_OPTIONS && _maven_cleanup
}
for _ARG in "$@"; do
  case $_ARG in
  set-version=*)
    maven_new_version="${_ARG#*=}"
    _update_version && exit_with_success "set version -> $maven_new_version"
    exit_with_error "unable to set version: $maven_new_version"
    ;;
  update)
    _update_dependencies && exit_with_success "updated dependencies"
    exit_with_error "unable to update dependencies"
    ;;
  *)
    exit_with_error "unknown arg: $_ARG"
    ;;
  esac
done
exit_with_error "no action was specified, expecting set-version=x.y.z or update"
