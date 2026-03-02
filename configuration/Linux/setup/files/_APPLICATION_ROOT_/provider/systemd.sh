#!/bin/sh
provider_path=~/.config/systemd/user
provider_path_is_dir=1
provider_no_root_user=1
if [ -e $provider_path ]; then
  provider_include=$(find "$provider_path" \( -type f -o \( -type l -path '*/multi-user.target.want/*' \) \) | sed -e 's/^.*\.config\/systemd\/user\///' | tr '\n' ' ')
fi
