#!/bin/sh
_chromium_install_extensions() {
  for provider_name in $(cat $_CONFIGURATION_DIRECTORY/extensions); do
    _chromium_install_extension
  done
}
_chromium_install_extension() {
  case $provider_name in
  ublock-origin)
    _github_fetch_latest_artifact gorhill uBlock uBlock0_ .chromium.zip
    ;;
  Browserpass)
    _github_fetch_latest_artifact browserpass browserpass-extension browserpass-github- .crx
    ;;
  Ghostery)
    artifact_url_function=_ghostery_artifact_url _github_fetch_latest_artifact ghostery ghostery-extension ghostery-chromium- .zip
    ;;
  *)
    log_warn "unsupported extension: $provider_name"
    continue
    ;;
  esac
}
_chromium_extension_load() {
  _chromium_extension_download_extract $1 $2 $3 || {
    browser_extension_delete=1 _chromium_extension_download_extract $1 $2 $3 || return 1
  }
  if [ -z "$registered_extensions" ]; then
    registered_extensions="$instance_directory/unpacked-extensions/$provider_name"
  else
    registered_extensions="$registered_extensions,$instance_directory/unpacked-extensions/$provider_name"
  fi
}
_chromium_extension_download_extract() {
  [ "$browser_extension_delete" ] && rm -f $conf_install_CACHE_PATH/$provider_name-$extension_version.crx.zip
  _download_fetch $1 ${2}-$3.crx.zip
  _extract_extract $conf_install_CACHE_PATH/$provider_name-$extension_version.crx.zip $instance_directory/unpacked-extensions/$provider_name
}
_ghostery_artifact_url() {
  version_without_v=$(printf '%s\n' "$3" | sed -e 's/^v//')
  git_github_artifact_url=https://github.com/$1/$2/releases/download/${3}/${4}${version_without_v}${5}
}
