#!/bin/sh
_synced_has_uncommitted_work() {
	[ -n "$(git status --porcelain)" ] && return 1
	return 0
}
_synced_synced_with_remote() {
	local _branch_name=$1
	local _remote_hash=$(_synced_remote_hash $_branch_name)
	local _local_hash=$(git-head)
	[ "$_local_hash" = "$_remote_hash" ]
}
_synced_remote_hash() {
	[ -z "$git_type" ] && git_type=heads
	git ls-remote $(git remote -v | head -1 | awk {'print$2'}) | grep "refs/$git_type/${1}$" | cut -f1
}
provider_path=${alt_path}$HOME/.data
provider_path_is_dir=1
provider_path_is_skip_prepare=1
_configuration_walterjwhite_data_clear() {
  local opwd=$PWD
  local data_project is_clean
  for data_project in $(find "$provider_path" -mindepth 2 -maxdepth 2 -type d -name .git | sed -e 's/\/.git//' -e 's/\.\///' | sort -u); do
    cd $data_project
    _synced_has_uncommitted_work || {
      log_warn "$data_project is dirty"
      is_clean=1
    }
    local branch_name=$(gcb)
    [ -z "$branch_name" ] && branch_name=master
    _synced_synced_with_remote $branch_name || {
      log_warn "$data_project is not synced with remote"
      is_clean=1
    }
    cd "$provider_path"
  done
  [ -e "${alt_path}$HOME"/.data ] && {
    find "${alt_path}$HOME"/.data -mindepth 1 -maxdepth 1 -type d ! -name configuration ! -name console -exec rm -rf {} +
  }
  return 0
}
_configuration_walterjwhite_data_restore() {
  [ ! -e $provider_data_path/applications ] && return 1
  system_id=$(_system_get_id)
  local data_application
  while read data_application; do
    if [ -e ${alt_path}$HOME/.data/$data_application ]; then
      log_warn "data application: $data_application already exists"
      continue
    fi
    HOME="${alt_path}$HOME" gclone data/$system_id/$USER/$data_application
  done <$provider_data_path/applications
}
_configuration_walterjwhite_data_backup() {
  rm -f $provider_data_path/applications
  local opwd=$PWD
  cd "$provider_path"
  local data_project
  for data_project in $(find "$provider_path" -mindepth 2 -maxdepth 2 -type d -name .git ! -path '*/configuration*' | sed -e 's/\/.git//' -e 's/\.\///' | sort -u); do
    printf '%s\n' "$data_project" | sed -e 's/^.*\.data\///' >>$provider_data_path/applications
    cd $data_project
    _synced_has_uncommitted_work || log_warn "$data_project is dirty"
    local branch_name=$(gcb)
    [ -z "$branch_name" ] && branch_name=master
    _synced_synced_with_remote $branch_name || log_warn "$data_project is not synced with remote"
    cd "$provider_path"
  done
  cd $opwd
}
