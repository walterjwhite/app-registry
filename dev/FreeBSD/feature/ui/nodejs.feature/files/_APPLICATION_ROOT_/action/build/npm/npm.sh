#!/bin/sh
_APPLICATION_NAME=dev
_NO_EXEC=1
for p in $(find . -type f -name package.json \
	\( ! -path '*/target/*' -and ! -path '*/.idea/*' -and ! -path '*/.git/*' -and ! -path '*/node_modules/*' \) | sed -e 's/\/package.json//'); do
	cd $p
	npm install
	npm run build
done
