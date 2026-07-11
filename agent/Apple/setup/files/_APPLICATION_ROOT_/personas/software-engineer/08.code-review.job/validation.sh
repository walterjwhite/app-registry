#!/bin/sh
_prompt_validation() {
  find . -type f -path '*/code-review.secret/*.md' -print -quit | grep -cqm1 '.'
}
