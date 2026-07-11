#!/bin/sh
_APPLICATION_NAME=dev
Dockerfile_find() {
	[ "$#" -ge 1 ] && shift
	find . -type f -name Dockerfile \
		\( ! -path '*/target/*' -and ! -path '*/.idea/*' -and ! -path '*/.git/*' -and ! -path '*/node_modules/*' -and -path "*/.docker/*" \) | sed -e 's/\/Dockerfile//'
}
