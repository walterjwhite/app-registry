#!/bin/sh
_APPLICATION_NAME=dev
git_find() {
	[ "$#" -ge 1 ] && shift
	git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 1
	find $(git rev-parse --git-dir) -mindepth 0 -maxdepth 0 -type d "$@"
}
