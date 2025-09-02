#!/bin/sh
set -a
_APPLICATION_NAME=secrets
git rm -rf $1 && git commit $1 -m "remove - $1" && git push
