#!/bin/sh
if [ -n "$conf_configuration_intellij_workspace_base_directory" ]; then
  provider_path="$conf_configuration_intellij_workspace_base_directory"
  provider_no_root_user=1
else
  log_warn "conf_configuration_intellij_workspace_base_directory is unset"
fi
_configuration_intellij_workspace_restore() {
  local intellij_idea
  for intellij_idea in $(find $APP_DATA_PATH/$provider_name -type d -name '.idea'); do
    local intellij_idea_target=$(printf '%s\n' "$intellij_idea" | sed -e "s|$APP_DATA_PATH/$provider_name||")
    log_detail "restoring $intellij_idea_target"
    rm -rf $conf_configuration_intellij_workspace_base_directory/$intellij_idea_target
    cp -Rp $APP_DATA_PATH/$provider_name/$intellij_idea_target $conf_configuration_intellij_workspace_base_directory/$intellij_idea_target
  done
}
_configuration_intellij_workspace_backup() {
  rm -rf $APP_DATA_PATH/$provider_name
  mkdir -p $APP_DATA_PATH/$provider_name
  local intellij_idea
  for intellij_idea in $(find $conf_configuration_intellij_workspace_base_directory -type d -name '.idea'); do
    local intellij_idea_target=$(printf '%s\n' "$intellij_idea" | sed -e "s|$conf_configuration_intellij_workspace_base_directory||")
    mkdir -p $(dirname $APP_DATA_PATH/$provider_name/$intellij_idea_target)
    log_detail "backing up $intellij_idea_target"
    cp -Rp $intellij_idea $APP_DATA_PATH/$provider_name/$intellij_idea_target
  done
}
