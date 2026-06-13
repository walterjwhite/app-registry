#!/bin/sh
if [ -n "$conf_configuration_intellij_workspace_base_directory" ]; then
  provider_path="$conf_configuration_intellij_workspace_base_directory"
  provider_no_root_user=1
else
  log_warn "conf_configuration_intellij_workspace_base_directory is unset"
fi
_configuration_intellij_workspace_restore() {
  local intellij_idea
  for intellij_idea in $(find $provider_data_path -type d -name '.idea'); do
    local intellij_idea_target=$(printf '%s\n' "$intellij_idea" | sed -e "s|$provider_data_path||")
    log_detail "restoring $intellij_idea_target"
    rm -rf $conf_configuration_intellij_workspace_base_directory/$intellij_idea_target
    cp -Rp $provider_data_path/$intellij_idea_target $conf_configuration_intellij_workspace_base_directory/$intellij_idea_target
  done
}
_configuration_intellij_workspace_backup() {
  rm -rf $provider_data_path
  mkdir -p $provider_data_path
  local intellij_idea
  for intellij_idea in $(find $conf_configuration_intellij_workspace_base_directory -type d -name '.idea'); do
    local intellij_idea_target=$(printf '%s\n' "$intellij_idea" | sed -e "s|$conf_configuration_intellij_workspace_base_directory||")
    mkdir -p $(dirname $provider_data_path/$intellij_idea_target)
    log_detail "backing up $intellij_idea_target"
    cp -Rp $intellij_idea $provider_data_path/$intellij_idea_target
  done
}
