#!/bin/sh
_APPLICATION_NAME=dev
_NO_EXEC=1
_format_shell_file() {
	local newfile=$(mktemp)
	grep '^#!/bin/sh' $1 >>$newfile
	grep -cqm1 '^#!/bin/sh' $1 && printf '\n' >>$newfile
	grep '^_REQUIRED_ARGUMENTS=' $1 >>$newfile
	grep -cqm1 '^_REQUIRED_ARGUMENTS=' $1 && printf '\n' >>$newfile
	grep '^lib ' $1 | sort -k 2 >>$newfile
	grep -cqm1 '^lib ' $1 && printf '\n' >>$newfile
	grep '^cfg ' $1 | sort -k 2 >>$newfile
	grep -cqm1 '^cfg ' $1 && printf '\n' >>$newfile
	grep '^init ' $1 | sort -k 2 >>$newfile
	grep -cqm1 '^init ' $1 && printf '\n' >>$newfile
	grep -Pv '^(lib |cfg |init |#!/bin/sh|_REQUIRED_ARGUMENTS=)' $1 >>$newfile
	chmod --reference=$1 $newfile
	mv $newfile $1
	sed -i '/^$/N;/\n$/D' $1
}
if [ "$#" -eq 0 ]; then
	SHELL_PATH=.
else
	SHELL_PATH="$*"
fi
for f in $(find $SHELL_PATH -type f -and \( -name '*.sh' -or -path '*/bin/*' \)); do
	_format_shell_file $f
done
