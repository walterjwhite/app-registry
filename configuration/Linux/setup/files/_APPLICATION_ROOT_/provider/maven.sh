#!/bin/sh
case $APP_PLATFORM_PLATFORM in
Apple)
  MAVEN_INSTALLATION_DIRECTORY=/opt/homebrew/Cellar/maven
  MAVEN_VERSION=$(ls -1 $_MAVEN_INSTALLATION_DIRECTORY | tail -1)
  provider_path="$_MAVEN_INSTALLATION_DIRECTORY/$_MAVEN_VERSION/libexec/conf"
  provider_path_is_dir=1
  ;;
Linux | FreeBSD | Windows)
  provider_path=~/.m2
  provider_path_is_dir=1
  ;;
esac
provider_include="settings.xml settings-security.xml"
provider_no_root_user=1
_configuration_maven_backup_post() {
  case $APP_PLATFORM_PLATFORM in
  Apple)
    touch "$provider_path"/logging
    ;;
  esac
}
