#!/bin/sh
provider_path=~/.gnupg
provider_path_is_dir=1
provider_exclude="random_seed .#*"
provider_no_root_user=1
_configuration_gnupg_restore_post() {
  chmod 700 "$provider_path"
}
