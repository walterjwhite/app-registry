_SHELL_TYPE=$(basename $(env | grep 'SHELL=.*' | head -1))
_load_plugins() {
	if [ ! -e $1/$_SHELL_TYPE ]; then
		return 1
	fi
	for _SHELL_SCRIPT_PLUGIN in $(find $1/$_SHELL_TYPE -type f); do
		. $_SHELL_SCRIPT_PLUGIN
	done
}
_load_plugins /usr/local/walterjwhite/console/shell
_load_plugins ~/.config/walterjwhite/shell
