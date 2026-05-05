#!/bin/sh
: ${conf_programming_languages_android_build_target:=Debug}
_android_run_build() {
  gradle wrapper --gradle-version \
    $(grep distributionUrl gradle/wrapper/gradle-wrapper.properties | sed -n 's/.*gradle-\([0-9.]*\)-bin.zip/\1/p')
  ./gradlew clean assemble${conf_programming_languages_android_build_target}
}
android_build_artifacts() {
  find . -name "*.apk" -type f
}
_android_is_android_project && {
  _android_run_build "$@"
  return
}
android_err_count=0
android_opwd=$PWD
for _ANDROID_PROJECT_DIR in $(extension_find_dirs_containing); do
  cd $_ANDROID_PROJECT_DIR
  _android_is_android_project || continue
  _android_run_build "$@" || {
    android_err_count=$(($android_err_count + 1))
  }
  cd $android_opwd
done
return $android_err_count
