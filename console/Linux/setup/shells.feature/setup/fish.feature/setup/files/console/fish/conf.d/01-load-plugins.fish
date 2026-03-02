set shell_type (basename (env | grep 'SHELL=.*' | head -1))
function _load_plugins
    if not test -e $argv[1]/$shell_type
        return
    end
    for shell_script_plugin in (find $argv[1]/$shell_type -type f)
        source $shell_script_plugin
    end
end
_load_plugins /usr/local/walterjwhite/console/shell
_load_plugins ~/.config/walterjwhite/shell
