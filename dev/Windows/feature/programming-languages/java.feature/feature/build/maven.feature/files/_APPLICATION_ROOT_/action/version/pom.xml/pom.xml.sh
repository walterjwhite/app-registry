#!/bin/sh
_APPLICATION_NAME=dev
_NO_EXEC=1
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
	mvn versions:set -DnewVersion=$_MAVEN_NEW_VERSION && _update_version_children && _maven_cleanup
}
_update_version_children() {
	_maven_has_child_modules && mvn -N versions:update-child-modules
	return 0
}
_update_dependencies() {
	mvn versions:$_CONF_DEV_MAVEN_DEPENDENCY_VERSION && mvn versions:update-properties $_OPTN_DEV_VERSION_MAVEN_PROPERTIES_OPTIONS && _maven_cleanup
}
for _ARG in "$@"; do
	case $_ARG in
	set=*)
		_MAVEN_NEW_VERSION="${_ARG#*=}"
		_update_version && _success "Set version -> $_MAVEN_NEW_VERSION"
		error "Unable to set version: $_MAVEN_NEW_VERSION"
		;;
	update)
		_update_dependencies && _success "Updated dependencies"
		error "Unable to update dependencies"
		;;
	*)
		error "Unknown arg: $_ARG"
		;;
	esac
done
error "No action was specified, expecting set=x.y.z or update"
