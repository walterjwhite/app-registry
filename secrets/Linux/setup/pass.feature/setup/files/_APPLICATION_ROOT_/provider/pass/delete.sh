#!/bin/sh
cd ~/.password-store
[ "$conf_secrets_force_delete" ] && pass_options="$pass_options -f"
pass rm -r $pass_options $1 && pass git push
