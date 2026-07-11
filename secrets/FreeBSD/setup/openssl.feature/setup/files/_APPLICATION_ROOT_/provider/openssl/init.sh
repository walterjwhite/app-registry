#!/bin/sh
_git_setup_mirror() {
  local remote_mirror=$1
  shift
  git remote add origin $remote_mirror
  case $remote_mirror in
  *@*)
    local git_tmp_dir=$(_mktemp_options=d _mktemp_mktemp)
    git clone . --mirror $git_tmp_dir
    _git_setup_mirror_scp && return
    _git_setup_mirror_tar
    exit_defer rm -rf $git_tmp_dir
    ;;
  http://* | https://*)
    log_warn "unable to setup mirror"
    ;;
  *)
    git clone . --mirror $remote_mirror
    ;;
  esac
}
_git_setup_mirror_scp() {
  command -v scp >/dev/null 2>&1 && {
    scp -r $git_tmp_dir $remote_mirror
    return
  }
}
_git_setup_mirror_tar() {
  local ssh_target=${remote_mirror%%:*}
  local remote_path=${remote_mirror#*:}
  tar -C $git_tmp_dir -cf - . | ssh $ssh_target "mkdir -p $remote_path && tar -C $remote_path -xf -"
}
: ${conf_secrets_openssl_key:=$HOME/.config/walterjwhite/secrets.openssl.key}
: ${conf_git_system_template_path:=/usr/share/git/templates}
: ${conf_git_clone_timeout:=30}
: ${conf_git_compression_format:=xz}
: ${conf_git_compression_cmd:="xz -z"}
: ${conf_git_squash_commits:=2}
: ${conf_git_backup_date_time_format:=%Y.%m.%d-%H.%M.%S}
: ${conf_git_delete_period_days:=365}
: ${conf_git_delete_dryrun:=0}
: ${conf_git_workspace_base_path:=$HOME/workspace}
: ${conf_git_workspace_base_branch:=dev}
: ${conf_git_project_base_path:=$HOME/projects}
readonly GIT_WORKSPACE_BASE_PATH=$conf_git_workspace_base_path
[ ! -e $HOME/.openssl-store ] && {
  git clone $git_mirror/secrets-openssl-store.git $HOME/.openssl-store || {
    git init $HOME/.openssl-store
    cd $HOME/.openssl-store
    touch .placeholder
    git add .placeholder
    git commit -am 'init'
    _git_setup_mirror $git_mirror/secrets-openssl-store.git && git push
  }
}
cd $HOME/.openssl-store
