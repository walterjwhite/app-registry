#!/bin/sh
android_is_runnable() {
  android_find -print -quit | grep -cqm1 '.'
}
android_find() {
  local opwd=$PWD
  for android_project_build_file in $(find . -type f -and \( -name "build.gradle.kts" -or -name "build.gradle" \) \
    ! -path '*/*.archived/*' \
    ! -path '*/*.secret/*' \
    ! -path '*/node_modules/*' \
    ! -path '*/target/*' \
    ! -path '*/.idea/*' \
    ! -path '*/.git/*' "$@"); do
    cd $(dirname $android_project_build_file)
    _android_is_android_project && printf '%s\n' "$PWD"
    cd $opwd
  done
}
_android_is_android_project() {
  [ ! -e build.gradle ] && [ ! -e build.gradle.kts ] && return 1
  grep -cqm1 "android {" build.gradle build.gradle.kts 2>/dev/null && return 0
  [ -f "src/main/AndroidManifest.xml" ] || [ -f "app/src/main/AndroidManifest.xml" ] && return 0
  return 1
}
