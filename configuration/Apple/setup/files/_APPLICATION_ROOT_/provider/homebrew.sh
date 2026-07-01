#!/bin/sh
provider_path=${alt_path}/opt/homebrew
provider_path_is_dir=1
_configuration_homebrew_restore() {
  [ ! -e $provider_data_path ] && return
  brew install $(cat $provider_data_path)
  return 0
}
_configuration_homebrew_backup() {
  rm -f $provider_data_path/homebrew
  brew bundle dump --file=$provider_data_path
  return 0
}
