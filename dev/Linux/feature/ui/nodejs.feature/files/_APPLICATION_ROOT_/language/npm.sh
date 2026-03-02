#!/bin/sh
_APPLICATION_NAME=dev
npm_find() {
	[ "$#" -ge 1 ] && shift
	find . -type f -name package.json \
		\( ! -path '*/target/*' -and ! -path '*/.idea/*' -and ! -path '*/.git/*' -and ! -path '*/node_modules/*' \) | sed -e 's/\/package.json//'
}
