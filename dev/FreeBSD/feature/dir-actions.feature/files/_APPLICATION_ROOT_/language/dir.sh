#!/bin/sh
_APPLICATION_NAME=dev
dir_find() {
	[ "$#" -ge 1 ] && shift
	find . -mindepth 0 -maxdepth 0 -type d "$@"
}
