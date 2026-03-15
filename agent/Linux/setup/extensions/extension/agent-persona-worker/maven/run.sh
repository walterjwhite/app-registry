#!/bin/sh
_agent_batch_extension_filter() {
  find . -maxdepth 1 -mindepth 1 -type d ! -name 'src' -exec rm -rf {} +
}
agent_batch_skip_root=1 agent_extension_batch
