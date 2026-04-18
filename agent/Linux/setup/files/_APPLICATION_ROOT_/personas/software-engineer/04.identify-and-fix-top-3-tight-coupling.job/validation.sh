#!/bin/sh
_prompt_validation() {
  find . -type f -path '*/tight-coupling.secret/*.md' -print -quit | grep -cqm1 '.' &&
    format && build
}
