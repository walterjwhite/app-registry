#!/bin/sh
provider_path=~/.saferc
provider_no_root_user=1
_configuration_vault_clear() {
  rm -f ~/.saferc ~/.svtoken
}
