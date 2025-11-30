#!/bin/sh
_APPLICATION_NAME=dev
shell_find() {
	shift
	find . -type f \( -name "*.sh" -or -path '*/bin/*' \) ! -path '*/node_modules/*' \
		! -path '*/target/*' \
		! -path '*/.idea/*' \
		! -path '*/.git/*' $@
}
