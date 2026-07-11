#!/bin/sh
provider_path=${alt_path}$HOME/Library/Preferences
provider_path_is_dir=1
provider_include="com.apple.Accessibility com.apple.AppleMultitouchTrackpad com.apple.HIToolbox com.apple.Kerberos com.apple.MCX com.apple.Preferences com.apple.ServicesMenu.Services com.apple.TTY com.apple.amp.mediasharingd com.apple.controlcenter com.apple.driver.AppleBluetoothMultitouch.mouse com.apple.driver.AppleHIDMouse com.apple.finder"
_configuration_apple_clear() {
  sudo_run rm -rf "$provider_path"/Caches
  sudo_run rm -rf "$provider_path"/Preferences
  return 0
}
_configuration_apple_backup_post() {
  _plutil_wrapper $provider_data_path plist xml1 xml _configuration_xmlformat
}
_configuration_xmlformat() {
  xmllint --format $1.xml -o $1.xml.formatted
  mv $1.xml.formatted $1.xml
}
_configuration_apple_restore_post() {
  _plutil_wrapper "$provider_path" xml binary1 plist
}
_plutil_wrapper() {
  local plist_file
  for plist_file in $(find $1 -type f -name "*.$2"); do
    local plist_base_name=$(printf '%s\n' "$plist_file" | sed -e "s/\.$2$//")
    plutil -convert $3 -o $plist_base_name.$4 $plist_file
    [ -n "$5" ] && $5 $plist_base_name
    rm -f $plist_file
  done
}
