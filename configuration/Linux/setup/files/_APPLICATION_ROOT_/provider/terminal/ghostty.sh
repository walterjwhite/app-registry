#!/bin/sh
command -v ghostty >/dev/null 2>&1 || {
  return
}
provider_path=${alt_path}$HOME/.config/ghostty/config
provider_no_root_user=1
