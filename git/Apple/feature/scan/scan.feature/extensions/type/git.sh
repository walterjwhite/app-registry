#!/bin/sh
_GIT_IS_RUNNABLE() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1
}
