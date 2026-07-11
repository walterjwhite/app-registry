#!/bin/sh
provider_path=${alt_path}$HOME/projects
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
  [ ! -e $provider_data_path/projects ] && return 1
  local opwd=$PWD
  local project
  while read project; do
    cd $opwd
    if [ -e ${alt_path}$HOME/.data/$project ]; then
      log_warn "data application: $project already exists"
      continue
    fi
    case $project in
    *\|*)
      project_branch=$(printf '%s' "$project" | cut -d'|' -f2)
      project=$(printf '%s' "$project" | cut -d'|' -f1)
      log_warn "restoring project: $project @ $project_branch"
      gclone_options="-b $project_branch"
      ;;
    esac
    project_full_path=$(HOME="${alt_path}$HOME" gclone $project $gclone_options | tail -1)
    [ -z "$project_full_path" ] && {
      log_warn "project path not found"
      continue
    }
    [ -z "$optn_configuration_projects_skip_build" ] && {
      command -v build >/dev/null 2>&1 && {
        cd "$project_full_path"
        build
      }
    }
  done <$provider_data_path/projects
}
_configuration_walterjwhite_projects_backup() {
  rm -f $provider_data_path/projects
  [ ! -e "$provider_path" ] && return
  local opwd=$PWD
  cd "$provider_path"
  local data_project
  for project in $(find "$provider_path" -name .git -type d ! -path '*/app.registry/*' ! -path '*/app-registry/*' |
    sed -e 's/\/.git//' -e 's/^.*\/projects\///' | sort -u); do
    printf '%s\n' "$project" | sed -e 's/git\///' -e 's/github.com/git@github.com/' >>$provider_data_path/projects
    cd $project
    _synced_has_uncommitted_work || log_warn "$project is dirty"
    local branch_name=$(gcb)
    [ -z "$branch_name" ] && branch_name=master
    _synced_synced_with_remote $branch_name || log_warn "$project is not synced with remote"
    cd "$provider_path"
  done
  cd $opwd
}
