#!/bin/sh
_APPLICATION_NAME=dev
if [ $# -eq 0 ]; then
	echo "Environment is required"
	exit 1
fi
set -a
case $1 in
dev | prod-auth | qa | load)
	environment=$1
	;;
*)
	echo "Invalid Environment: $1"
	exit 2
	;;
esac
echo "Targeting: $environment"
k6 run load.js
