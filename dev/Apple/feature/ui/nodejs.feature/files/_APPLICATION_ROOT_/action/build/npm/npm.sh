#!/bin/sh
_APPLICATION_NAME=dev
if [ "$#" -eq "0" ]; then
	find . -type f -name 'package.json' -execdir npm install {} \;
else
	opwd=$PWD
	for _NPM_PROJECT_PATH in "$@"; do
		cd $_NPM_PROJECT_PATH
		npm install
		cd $opwd
	done
	unset opwd
fi
_NO_EXEC=1
