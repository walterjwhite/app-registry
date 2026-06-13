#!/bin/sh
'[ "$(find "$1" -path "$1/*" -prune -type l -exec sh -c "for file; do echo .; done" innersh \{\} + | wc -l)" -gt 0 ]'
outersh {} \; -print | sort -V
'[ "$(find "$1" -path "$1/*" -prune -type l \( -name "*.jpg" -or -name "*.mp4" \) -exec sh -c "for file; do echo .; done" innersh \{\} + | wc -l)" -gt 100 ]'
outersh {} \; -print | sort -V
'[ "$(find "$1" -path "$1/*" -prune -type l \( -name '*.jpg' -or -name '*.mp4' \) -exec sh -c "for file; do echo .; done" innersh \{\} + | wc -l)" -gt 0 ]'
outersh {} \; -print | sort -V
'[ "$(find $1 -path $1/* -prune -type l \( -name *.jpg -or -name *.mp4 \) -exec sh -c for file; do echo .; done innersh \{\} + | wc -l)" -gt 0 ]'
outersh {} \; -print | sort -V
