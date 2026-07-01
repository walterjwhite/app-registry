#!/bin/sh
_APPLICATION_NAME=dev
python_find() {
	shift
	find . -type f -name "*.py" ! -path '*/node_modules/*' \
		! -path '*/target/*' \
		! -path '*/.idea/*' \
		! -path '*/.git/*' $@
}
