#!/bin/sh
_APPLICATION_NAME=dev
gcloud_find() {
	[ "$#" -ge 1 ] && shift
	find . -type f -name gcloud \
		\( ! -path '*/target/*' -and ! -path '*/.idea/*' -and ! -path '*/.git/*' -and ! -path '*/node_modules/*' \) | sed -e 's/\/gcloud//'
}
