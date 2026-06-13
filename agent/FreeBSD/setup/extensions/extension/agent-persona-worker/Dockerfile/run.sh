#!/bin/sh
_agent_batch_extension_filter() {
  find . -type f ! -path '*/.build/*' -exec rm -f {} +
}
file_extension_filter="Dockerfile" agent_extension_batch
