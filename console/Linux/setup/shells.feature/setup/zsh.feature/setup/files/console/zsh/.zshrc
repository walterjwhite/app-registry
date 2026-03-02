shell_type=$(basename $(env | grep 'SHELL=.*' | head -1))
_load_plugins() {
	[ ! -e $1/$shell_type ] && return
	for shell_script_plugin in $(find $1/$shell_type -type f); do
		. $shell_script_plugin
	done
}
_load_plugins /usr/local/walterjwhite/console/shell
_load_plugins ~/.config/walterjwhite/shell
