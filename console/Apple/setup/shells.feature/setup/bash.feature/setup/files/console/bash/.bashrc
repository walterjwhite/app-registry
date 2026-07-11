shell_type=$(basename $(env | grep 'SHELL=.*' | head -1))
_load_plugins() {
	if [ ! -e $1/$shell_type ]; then
		return 1
	fi
	for shell_script_plugin in $(find $1/$shell_type -type f); do
		. $shell_script_plugin
	done
}
_load_plugins $APP_PATH/shell
_load_plugins ~/.config/walterjwhite/shell
