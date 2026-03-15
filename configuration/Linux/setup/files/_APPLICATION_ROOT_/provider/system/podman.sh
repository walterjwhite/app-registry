#!/bin/sh
which podman >/dev/null 2>&1 || {
  return
}
provider_path=~/.config/containers
provider_path_is_dir=1
provider_include="containers.conf"
provider_no_root_user=1
