#!/bin/sh
git_is_runnable() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1
}
