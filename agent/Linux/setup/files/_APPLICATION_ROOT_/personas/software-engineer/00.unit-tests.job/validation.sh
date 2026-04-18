#!/bin/sh
agent_documentation_path=unit-tests.secret
_agent_validate_prompt_output() {
  case $agent_extension_type in
  maven)
    _jacoco_validation
    ;;
  esac
}
