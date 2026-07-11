#!/bin/sh
provider_path=${alt_path}$HOME/.saferc
provider_no_root_user=1
_configuration_vault_clear() {
  rm -f ${alt_path}$HOME/.saferc ${alt_path}$HOME/.svtoken
}
