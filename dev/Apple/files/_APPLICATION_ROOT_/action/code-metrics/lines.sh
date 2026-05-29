#!/bin/sh
_APPLICATION_NAME=dev
_FILE_TYPES=$(find . -type f ! -path '*/.git/*' ! -path '*/target/*' | sed -e "s/^.*\.//" |
	$_CONF_GNU_GREP -P "^[a-zA-Z][\w]{1,3}$" |
	sort -u | tr '\n' ' ')
for _FILE_TYPE in $_FILE_TYPES; do
	find . -type f -name "*.$_FILE_TYPE" ! -path '*/.git/*' ! -path '*/target/*' -exec wc -l {} + |
		grep total | sed -e "s/total/total ($_FILE_TYPE)/"
done
