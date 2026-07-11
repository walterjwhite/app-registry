#!/bin/sh
if [ $# -eq 0 ]; then
  echo "Environment is required"
  exit 1
fi
set -a
case $1 in
dev | prod-auth | qa | load)
  test_environment=$1
  ;;
*)
  echo "Invalid Environment: $1"
  exit 2
  ;;
esac
echo "Targeting: $test_environment"
k6 run load.js
