#!/bin/sh
_APPLICATION_NAME=dev
python_find() {
	[ "$#" -ge 1 ] && shift
	find . -type f -name "*.py" ! -path '*/node_modules/*' \
		! -path '*/target/*' \
		! -path '*/.idea/*' \
		! -path '*/.git/*' "$@"
}
