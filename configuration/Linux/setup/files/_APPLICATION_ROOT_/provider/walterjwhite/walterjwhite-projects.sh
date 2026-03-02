#!/bin/sh
provider_path=~/projects
provider_path_is_dir=1
provider_path_is_skip_prepare=1
_configuration_walterjwhite_projects_clear() {
  [ ! -e "$provider_path" ] && return
  log_info "clearing projects"
  local opwd=$PWD
  cd "$provider_path"
  local project
  for project in $(find . -type d -name .git -execdir pwd \;); do
    log_info "clearing project: $project"
    cd $project
    _git-is-clean || log_warn "$project is dirty"
    gpush --all || log_warn "unable to push all refs"
    gpush --tags || log_warn "unable to push all tags"
    cd "$provider_path"
  done
  cd $opwd
}
_configuration_walterjwhite_projects_restore() {
  [ ! -e $APP_DATA_PATH/$provider_name/projects ] && return 1
  local opwd=$PWD
  local project
  while read project; do
    if [ -e ~/.data/$project ]; then
      log_warn "data application: $project already exists"
      continue
    fi
    gclone $project
    cd $opwd
  done <$APP_DATA_PATH/$provider_name/projects
}
_configuration_walterjwhite_projects_backup() {
  rm -f $APP_DATA_PATH/$provider_name/projects
  [ ! -e "$provider_path" ] && return
  local opwd=$PWD
  cd "$provider_path"
  local data_project
  for project in $(find "$provider_path" -name .git -type d ! -path '*/app.registry/*' ! -path '*/app-registry/*' |
    sed -e 's/\/.git//' -e 's/^.*\/projects\///' | sort -u); do
    printf '%s\n' "$project" | sed -e 's/git\///' -e 's/github.com/git@github.com/' >>$APP_DATA_PATH/$provider_name/projects
    cd $project
    _synced_has_uncommitted_work || log_warn "$project is dirty"
    local branch_name=$(gcb)
    [ -z "$branch_name" ] && branch_name=master
    _synced_synced_with_remote $branch_name || log_warn "$project is not synced with remote"
    cd "$provider_path"
  done
  cd $opwd
}
