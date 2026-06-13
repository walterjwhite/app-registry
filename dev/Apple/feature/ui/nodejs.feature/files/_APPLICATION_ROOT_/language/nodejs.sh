#!/bin/sh
_APPLICATION_NAME=dev
nodejs_find() {
	shift
	find . -type d -name node_modules \
		! -path '*/target/*' \
		! -path '*/.idea/*' \
		! -path '*/.git/*' $@
}
