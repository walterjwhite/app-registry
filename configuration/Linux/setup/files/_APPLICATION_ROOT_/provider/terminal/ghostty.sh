#!/bin/sh
which ghostty >/dev/null 2>&1 || {
  return
}
provider_path=~/.config/ghostty/config
provider_no_root_user=1
