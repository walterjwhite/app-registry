#!/bin/sh
set -a
_APPLICATION_NAME=gentoo-installer
_beep() {
	[ ! -e /dev/speaker ] && return 1
	flock -n -w 0 $RSRC_BEEP printf '%s' "$1" >/dev/speaker || {
		_DEBUG "Another 'beep' is in progress"
		return 2
	}
}
_sudo_precmd() {
	_beep $_CONF_LOG_SUDO_BEEP_TONE
}
_environment_filter() {
	$_CONF_GNU_GREP -P "(^_CONF_|^_OPTN_|^_INSTALL_|^${_TARGET_APPLICATION_NAME}_)"
}
_environment_dump() {
	[ -z "$_APPLICATION_PIPE_DIR" ] && return
	[ -z "$_ENVIRONMENT_FILE" ] && _ENVIRONMENT_FILE=$_APPLICATION_PIPE_DIR/environment
	mkdir -p $(dirname $_ENVIRONMENT_FILE)
	env | _environment_filter | sort -u | grep -v '^$' | sed -e 's/=/="/' -e 's/$/"/' >>$_ENVIRONMENT_FILE
}
_call() {
	local _function_name=$1
	type $_function_name >/dev/null 2>&1 || {
		_DEBUG "${_function_name} does not exist"
		return 255
	}
	[ $# -gt 1 ] && {
		shift
		$_function_name "$@"
		return $?
	}
	$_function_name
}
_() {
	_reset_indent
	if [ -n "$_EXEC_ATTEMPTS" ]; then
		local attempt=1
		while [ $attempt -le $_EXEC_ATTEMPTS ]; do
			_WARN_ON_ERROR=1 _do_exec "$@" && return
			attempt=$(($attempt + 1))
		done
		_ERROR "Failed after $attempt attempts: $*"
	fi
	_do_exec "$@"
}
_do_exec() {
	local _successfulExitStatus=0
	if [ -n "$_SUCCESSFUL_EXIT_STATUS" ]; then
		_successfulExitStatus=$_SUCCESSFUL_EXIT_STATUS
		unset _SUCCESSFUL_EXIT_STATUS
	fi
	_INFO "## $*"
	local exit_status
	if [ -z "$_DRY_RUN" ]; then
		"$@"
		exit_status=$?
	else
		_WARN "using dry run status: $_DRY_RUN"
		exit_status=$_DRY_RUN
	fi
	if [ $exit_status -ne $_successfulExitStatus ]; then
		if [ -n "$_ON_FAILURE" ]; then
			$_ON_FAILURE
			return
		fi
		if [ -z "$_WARN_ON_ERROR" ]; then
			_ERROR "Previous cmd failed: $* - $exit_status"
		else
			unset _WARN_ON_ERROR
			_WARN "Previous cmd failed: $* - $exit_status"
			_ENVIRONMENT_FILE=$(_mktemp error) _environment_dump
			return $exit_status
		fi
	fi
}
_ERROR() {
	if [ $# -ge 2 ]; then
		_EXIT_STATUS=$2
	else
		_EXIT_STATUS=1
	fi
	_EXIT_LOG_LEVEL=4
	_EXIT_STATUS_CODE="ERR"
	_EXIT_COLOR_CODE="$_CONF_LOG_C_ERR"
	_EXIT_MESSAGE="$1 ($_EXIT_STATUS)"
	_EXIT_BEEP=$_CONF_LOG_BEEP_ERR
	_defer _environment_dump
	_defer _log_app_exit
	exit $_EXIT_STATUS
}
_success() {
	_EXIT_STATUS=0
	_EXIT_LOG_LEVEL=1
	_EXIT_STATUS_CODE="SCS"
	_EXIT_COLOR_CODE="$_CONF_LOG_C_SCS"
	_EXIT_MESSAGE="$1"
	_EXIT_BEEP=$_CONF_LOG_BEEP_SCS
	_defer _long_running_cmd
	_defer _log_app_exit
	[ -z "$_EXIT" ] && exit 0
}
_on_exit() {
	[ $_EXIT ] && return 1
	_EXIT=0
	[ -z "$_EXIT_STATUS" ] && _success "completed successfully"
	if [ -n "$_DEFERS" ]; then
		local defer
		for defer in $_DEFERS; do
			_call $defer
		done
		unset _DEFERS
	fi
	return $_EXIT
}
_defer() {
	if [ -n "$_DEFERS" ]; then
		local defer
		for defer in $_DEFERS; do
			[ "$defer" = "$1" ] && {
				_DEBUG "not deferring: $1 as it was already deferred"
				return
			}
		done
	fi
	_DEBUG "deferring: $1"
	_DEFERS="$1 $_DEFERS"
}
_log_app_exit() {
	[ "$_EXIT_MESSAGE" ] && {
		local current_time=$(date +%s)
		local timeout=$(($_APPLICATION_START_TIME + $_CONF_LOG_BEEP_TIMEOUT))
		[ $current_time -le $timeout ] && unset _EXIT_BEEP
		_print_log $_EXIT_LOG_LEVEL "$_EXIT_STATUS_CODE" "$_EXIT_COLOR_CODE" "$_EXIT_BEEP" "$_EXIT_MESSAGE"
	}
	_log_app exit
	[ -n "$_LOGFILE" ] && [ -n "$_OPTN_LOG_EXIT_CMD" ] && {
		$_OPTN_LOG_EXIT_CMD -file $_LOGFILE
	}
}
_include() {
	local include_file
	for include_file in "$@"; do
		[ -f $HOME/.config/walterjwhite/$include_file ] && . $HOME/.config/walterjwhite/$include_file
	done
}
_WARN() {
	_print_log 3 WRN "$_CONF_LOG_C_WRN" "$_CONF_LOG_BEEP_WRN" "$1"
}
_INFO() {
	_print_log 2 INF "$_CONF_LOG_C_INFO" "$_CONF_LOG_BEEP_INFO" "$1"
}
_DETAIL() {
	_print_log 2 DTL "$_CONF_LOG_C_DETAIL" "$_CONF_LOG_BEEP_DETAIL" "$1"
}
_DEBUG() {
	_print_log 1 DBG "$_CONF_LOG_C_DEBUG" "$_CONF_LOG_BEEP_DEBUG" "($$) $1"
}
_sed_remove_nonprintable_characters() {
	sed -e 's/[^[:print:]]//g'
}
_print_log() {
	if [ -z "$5" ]; then
		if test ! -t 0; then
			local _line
			cat - | _sed_remove_nonprintable_characters |
				while read _line; do
					_print_log $1 $2 $3 $4 "$_line"
				done
			return
		fi
		return
	fi
	local message="$5"
	[ $1 -lt $_CONF_LOG_LEVEL ] && return
	[ -n "$_LOGGING_CONTEXT" ] && message="$_LOGGING_CONTEXT - $message"
	if [ $_BACKGROUNDED ] && [ $_OPTN_INSTALL_BACKGROUND_NOTIFICATION_METHOD ]; then
		$_OPTN_INSTALL_BACKGROUND_NOTIFICATION_METHOD "$2" "$_message" &
	fi
	[ -n "$4" ] && _beep "$4"
	_log_to_file "$2" "${_LOG_INDENT}$message"
	_log_to_console "$3" "${_LOG_INDENT}$message"
	[ -z "$INTERACTIVE" ] && _syslog "$message"
	return 0
}
_reset_indent() {
	unset _LOG_INDENT
}
_log_to_file() {
	[ -z "$_LOGFILE" ] && return
	printf '%s\n' "$2" >>$_LOGFILE
}
_log_to_console() {
	[ -z "$_CONF_LOG_CONSOLE" ] && return
	printf >&$_CONF_LOG_CONSOLE '\033[%s%s \033[0m\n' "$1" "$2"
}
_log_app() {
	_DEBUG "$_APPLICATION_NAME:$_APPLICATION_CMD - $1 ($$)"
}
_mktemp() {
	local suffix=$1
	[ -n "$suffix" ] && suffix=".$suffix"
	local sudo_prefix
	[ -n "$_SUDO_USER" ] && sudo_prefix=_sudo
	$sudo_prefix mktemp -${_MKTEMP_OPTIONS}t ${_APPLICATION_NAME}.${_APPLICATION_CMD}${suffix}.XXXXXXXX
}
_parent_processes_pgrep() {
	pgrep -P $1
}
_interactive_alert_if() {
	_is_interactive_alert_enabled && _interactive_alert "$@"
}
_is_interactive_alert_enabled() {
	grep -cq '^_OPTN_INSTALL_INTERACTIVE_ALERT=1$' $_CONF_APPLICATION_CONFIG_PATH 2>/dev/null
}
_read_ifs() {
	stty -echo
	_read_if "$@"
	stty echo
}
_read_if() {
	if [ $(env | grep -c "^$2=.*") -eq 1 ]; then
		_DEBUG "$2 is already set"
		return 1
	fi
	[ -z "$INTERACTIVE" ] && _ERROR "Running in non-interactive mode and user input was requested: $@" 10
	_print_log 9 STDI "$_CONF_LOG_C_STDIN" "$_CONF_LOG_BEEP_STDIN" "$1 $3"
	_interactive_alert_if $1 $3
	read -r $2
}
_syslog() {
	logger -i -t "$_APPLICATION_NAME.$_APPLICATION_CMD" "$1"
}
_sudo() {
	[ $# -eq 0 ] && _ERROR 'No arguments were provided to _sudo'
	_sudo_is_required || {
		"$@"
		return
	}
	_require "$_SUDO_CMD" "_SUDO_CMD - $*"
	[ -n "$INTERACTIVE" ] && {
		$_SUDO_CMD -n ls >/dev/null 2>&1 || _sudo_precmd "$@"
	}
	$_SUDO_CMD $sudo_options "$@"
	unset sudo_options
}
_sudo_is_required() {
	[ -n "$_SUDO_USER" ] && {
		[ "$_SUDO_USER" = "$USER" ] && return 1
		sudo_options="$sudo_options -u $_SUDO_USER"
		return 0
	}
	[ "$USER" = "root" ] && return 1
	return 0
}
_require() {
	local level=_ERROR
	if [ -z "$1" ]; then
		[ -n "$_WARN_ON_ERROR" ] && level=_WARN
		$level "$2 required $_REQUIRE_DETAILED_MESSAGE" $3
		return 1
	fi
	unset _REQUIRE_DETAILED_MESSAGE
}
_mail() {
	if [ $# -lt 3 ]; then
		_WARN "recipients[0], subject[1], message[2] is required - $# arguments provided"
		return 1
	fi
	local recipients=$(printf '%s' "$1" | tr '|' ' ')
	shift
	local subject="$1"
	shift
	local message="$1"
	shift
	printf "$message" | mail -s "$subject" $recipients
}
_alert() {
	_print_log 5 ALRT "$_CONF_LOG_C_ALRT" "$_CONF_LOG_BEEP_ALRT" "$1"
	local recipients="$_OPTN_LOG_ALERT_RECIPIENTS"
	local subject="Alert: $0 - $1"
	if [ -z "$recipients" ]; then
		_WARN "recipients is empty, aborting"
		return 1
	fi
	_mail "$recipients" "$subject" "$2"
}
_long_running_cmd() {
	[ -n "$_OPTN_DISABLE_LONG_RUNNING_CMD_NOTIFICATION" ] && return
	_APPLICATION_END_TIME=$(date +%s)
	_APPLICATION_RUNTIME=$(($_APPLICATION_END_TIME - $_APPLICATION_START_TIME))
	[ $_APPLICATION_RUNTIME -lt $_CONF_LOG_LONG_RUNNING_CMD ] && return
	local subject="[$_APPLICATION_NAME] - $_EXIT_MESSAGE - ($_EXIT_STATUS)"
	local message=""
	if [ -n "$_LOGFILE" ]; then
		message=$(tail -$_CONF_LOG_LONG_RUNNING_CMD_LINES $_LOGFILE | _sed_remove_nonprintable_characters)
	fi
	_alert "$subject" "$message"
}
_() {
	_DETAIL "### $*"
	"$@" || {
		_WARN "init _ERROR: $?"
		[ -n "$_WARN_ON_ERROR" ] && return
		_on_exit
	}
	_INFO "    completed: $*"
}
_on_exit() {
	exec /bin/sh
	return 1
}
_mount_filesystems() {
	mount -t proc proc /proc
	mount -t sysfs sysfs /sys
	mount -t devtmpfs devtmpfs /dev
	mount -t tmpfs -o rw,nosuid,nodev,relatime,mode=755 none /run
}
_MODULES_UDEV() {
	/usr/lib/systemd/systemd-udevd --daemon --resolve-names=never
	udevadm trigger
	udevadm settle
}
_MODULES_HOST() {
	modprobe -a KERNEL_HOST_MODULES
	return 0
}
_process_cmdline() {
	local overlayfs_size=$(cat /proc/cmdline | tr ' ' '\n' | grep overlayfs.size | cut -f2 -d=)
	[ -n "$overlayfs_size" ] && {
		OVERLAYFS_SIZE=$overlayfs_size
		_DETAIL "overlayfs size: $OVERLAYFS_SIZE"
	}
	LUKS_DEVICE_UUID=$(cat /proc/cmdline | tr ' ' '\n' | grep luks.uuid | cut -f2 -d=)
	_DETAIL "luks uuid: $LUKS_DEVICE_UUID"
	RAM_DISABLED=$(cat /proc/cmdline | tr ' ' '\n' | grep ram.disabled | cut -f2 -d=)
	_DETAIL "ram disabled: $RAM_DISABLED"
	cat /proc/cmdline | grep -qm1 'init.debug' >/dev/null 2>&1 && {
		_DETAIL "enabling init debug"
		set -x
	}
}
_wait_for_device() {
	local tries=3
	while [ $tries -gt 0 ]; do
		LUKS_DEVICE_PATH=$(findfs UUID=$LUKS_DEVICE_UUID)
		[ -n "$LUKS_DEVICE_PATH" ] && return
		sleep 3
		tries=$(($tries - 1))
	done
	return 1
}
_cryptsetup_open() {
	_read_ifs "Enter passphrase for $LUKS_DEVICE_PATH" _LUKS_KEY
	printf '%s' "$_LUKS_KEY" | cryptsetup luksOpen $LUKS_DEVICE_PATH luks-$LUKS_DEVICE_UUID
}
_mount_root_volume() {
	_ mkdir -p /run/root-volume
	_ mount -o ro /dev/mapper/luks-$LUKS_DEVICE_UUID /run/root-volume
}
_ram() {
	[ -n "$RAM_DISABLED" ] && return 1
	local system_memory=$(cat /proc/meminfo | grep MemTotal | awk {'print$2'})
	system_memory=$(($system_memory * 1024))
	local root_imgsize=$(stat -c %s /run/root-volume/root-squashfs.img)
	local memory_required=$(($root_imgsize + $OVERLAYFS_SIZE))
	[ $memory_required -ge $system_memory ] && {
		_DETAIL "System has insufficent memory to run in memory"
		VOLUME_PATH=root-volume
		return
	}
	_DETAIL "Resizing /run volume to match size of images: [$root_imgsize] [$system_memory]"
	mount -o remount,size=$root_imgsize /run
	mkdir -p /run/root-image
	_DETAIL 'Copying image into memory'
	rsync -h --info=progress /run/root-volume/root-squashfs.img /run/root-image/root-squashfs.img
	_DETAIL 'Copied image into memory'
	VOLUME_PATH=root-image
}
_overlay() {
	[ ! -e /run/$VOLUME_PATH/$1-squashfs.img ] && return
	local target_mount=$2
	[ -z "$target_mount" ] && target_mount=/mnt/$1-rw
	mkdir -p /mnt/$1-overlay /mnt/$1-ro $target_mount
	mount /run/$VOLUME_PATH/$1-squashfs.img /mnt/$1-ro
	mount -t tmpfs -o size=$OVERLAYFS_SIZE tmpfs /mnt/$1-overlay
	mkdir -p /mnt/$1-overlay/rw /mnt/$1-overlay/work
	mount -t overlay overlay -o lowerdir=/mnt/$1-ro,upperdir=/mnt/$1-overlay/rw,workdir=/mnt/$1-overlay/work $target_mount
}
_read_rw() {
	/mnt/root-rw/usr/local/bin/read-rw mnt/root-rw
}
_cleanup() {
	[ "$VOLUME_PATH" != "root-volume" ] && {
		umount /run/root-volume
		cryptsetup luksClose luks-$LUKS_DEVICE_UUID
	}
	mkdir -p /mnt/live
	mount -o remount,rw /run/root-volume
	mount --bind /run/root-volume /mnt/live
	unset OVERLAYFS_SIZE VOLUME_PATH LUKS_DEVICE_UUID
}
_switch_root() {
	mount --move /proc /mnt/root-rw/proc
	mount --move /sys /mnt/root-rw/sys
	mount --move /dev /mnt/root-rw/dev
	mkdir -p /mnt/root-rw/mnt/overlay/root
	mount --bind /mnt/root-overlay/rw /mnt/root-rw/mnt/overlay/root
	_DETAIL "Changes are visible @ /mnt/overlay"
	exec switch_root /mnt/root-rw /sbin/init
}
_include logging platform context wait beep paths net . gentoo-installer
: ${_CONF_LOG_HEADER:="##################################################"}
: ${_CONF_LOG_C_ALRT:="1;31m"}
: ${_CONF_LOG_C_ERR:="1;31m"}
: ${_CONF_LOG_C_SCS:="1;32m"}
: ${_CONF_LOG_C_WRN:="1;33m"}
: ${_CONF_LOG_C_INFO:="1;36m"}
: ${_CONF_LOG_C_DETAIL:="1;0;36m"}
: ${_CONF_LOG_C_DEBUG:="1;35m"}
: ${_CONF_LOG_C_STDIN:="1;34m"}
: ${_CONF_LOG_DATE_FORMAT:="%Y/%m/%d|%H:%M:%S"}
: ${_CONF_LOG_DATE_TIME_FORMAT:="%Y/%m/%d %H:%M:%S"}
: ${_CONF_LOG_LEVEL:=2}
: ${_CONF_LOG_INDENT:="  "}
: ${_CONF_LOG_CONF_VALIDATION_FUNCTION:=warn}
: ${_CONF_LOG_WAITER_LEVEL:=debug}
: ${_CONF_LOG_FEATURE_TIMEOUT_ERROR_LEVEL:=warn}
: ${_CONF_LOG_LONG_RUNNING_CMD:=30}
: ${_CONF_LOG_LONG_RUNNING_CMD_LINES:=1000}
[ -t 0 ] && INTERACTIVE=1
: ${_CONF_LOG_CONSOLE:=2}
: ${LIB:="beep.sh context.sh environment.sh exec.sh exit.sh help.sh include.sh logging.sh mktemp.sh platform.sh processes.sh stdin.sh syslog.sh sudo.sh wait.sh validation.sh net/mail.sh alert.sh"}
: ${CFG:="logging platform context wait beep paths net"}
: ${SUPPORTED_PLATFORMS:="Apple FreeBSD Linux Windows"}
which pgrep >/dev/null 2>&1 && _PARENT_PROCESSES_FUNCTION=_parent_processes_pgrep
_DETECTED_PLATFORM=$(uname)
case $_DETECTED_PLATFORM in
Darwin)
	_DETECTED_PLATFORM=Apple
	;;
MINGW64_NT-*)
	_DETECTED_PLATFORM=Windows
	;;
esac
_PLATFORM="Linux"
: ${_CONF_GNU_GREP:=grep}
: ${_CONF_GNU_SED:=sed}
_ARCHITECTURE=$(uname -m)
_SUDO_CMD="sudo"
_PLATFORM_PACKAGES="dev-vcs/git net-misc/curl dev-util/sh"
NPM_PACKAGE="net-libs/nodejs"
RUST_PACKAGE="rust"
PYPI_PACKAGE="dev-lang/python"
GO_PACKAGE="dev-lang/go"
EXPECT_PACKAGE="dev-tcltk/expect"
: ${_CONF_LOG_SUDO_BEEP_TONE:=L32aL8fL32c}
: ${_CONF_INSTALL_STAT_ARGUMENTS:='-f %OLp'}
: ${_CONF_INSTALL_CONTEXT:=$_CONSOLE_CONTEXT_ID}
: ${_CONF_INSTALL_CONTEXT:=default}
: ${_CONF_WAIT_INTERVAL:=30}
: ${RSRC_BEEP:=/tmp/beep}
: ${_CONF_LOG_BEEP_TIMEOUT:=5}
: ${_CONF_LOG_BEEP_ERR:='L32c'}
: ${_CONF_LOG_BEEP_ALRT:='L32f'}
: ${_CONF_LOG_BEEP_SCS:='L32a'}
: ${_CONF_LOG_BEEP_WRN:=''}
: ${_CONF_LOG_BEEP_INFO:=''}
: ${_CONF_LOG_BEEP_DETAIL:=''}
: ${_CONF_LOG_BEEP_DEBUG:=''}
: ${_CONF_LOG_BEEP_STDIN:='L32ab'}
[ "$HOME" = "/" ] && HOME=/root
: ${_CONF_LIBRARY_PATH:=/usr/local/walterjwhite}
: ${_CONF_BIN_PATH:=/usr/local/bin}
_CONF_DATA_PATH=$HOME/.data
_CONF_CACHE_PATH=$_CONF_DATA_PATH/.cache
_CONF_CONFIG_PATH=$HOME/.config/walterjwhite
_CONF_RUN_PATH=/tmp/$USER/walterjwhite/app
_CONF_DATA_ARTIFACTS_PATH=$_CONF_DATA_PATH/install-v2/artifacts
_CONF_DATA_REGISTRY_PATH=$_CONF_DATA_PATH/install-v2/registry
_CONF_APPLICATION_DATA_PATH=$_CONF_DATA_PATH/$_APPLICATION_NAME
_CONF_APPLICATION_CONFIG_PATH=$_CONF_CONFIG_PATH/$_APPLICATION_NAME
_CONF_APPLICATION_LIBRARY_PATH=$_CONF_LIBRARY_PATH/$_APPLICATION_NAME
: ${_CONF_NETWORK_TEST_TIMEOUT:=5}
: ${_CONF_NETWORK_TEST_TARGETS:="http://connectivity-check.ubuntu.com http://example.org http://www.google.com http://telehack.com http://lxer.com"}
: ${_CONF_GENTOO_INSTALLER_VERSION:=20250105T170325Z}
: ${_CONF_GENTOO_VERBOSE_TAR:=}
: ${_CONF_GENTOO_INSTALL_PATH:=/mnt/gentoo}
: ${INCUS_CLEANUP_EXISTING=N}
: ${MODULES_IMPLEMENTATION:=host}
: ${GENTOO_STAGE3_TYPE:="hardened-openrc"}
: ${GENTOO_KERNEL:=gentoo-kernel}
: ${GENTOO_INIT:=DRACUT}
: ${GENTOO_BOOT_LOADER:=EFIBOOTMGR}
: ${GENTOO_BOOT_METHOD:=UEFI}
: ${GENTOO_BOOT_FS:=zpool}
: ${GENTOO_CRON:=DCRON}
: ${GENTOO_SYSLOG:=SYSKLOGD}
: ${GENTOO_SYSLOG_USE:=logrotate}
: ${GENTOO_INDEXING:=PLOCATE}
: ${GENTOO_L10N:="en en-US"}
: ${GENTOO_LUKS_CIPHER:=aes-xts-plain}
: ${GENTOO_LUKS_KEY_SIZE:=512}
: ${GENTOO_LUKS_HASH:=sha512}
: ${GENTOO_SOFTWARE_LICENSE:="@FREE @BINARY-REDISTRIBUTABLE"}
: ${GENTOO_TIME_SYNCHRONIZATION:=CHRONY}
: ${GENTOO_KERNEL:=gentoo-kernel}
: ${GENTOO_KERNEL_CMDLINE_ARGS:="consoleblank=300 quiet"}
: ${_CONF_GENTOO_INSTALLER_SYSTEM_IDENTIFICATION:="/usr/local/etc/walterjwhite/system"}
: ${GENTOO_SYSTEM_LOCALE_ESELECT:=en_US.utf8}
: ${GENTOO_SYSTEM_LOCALE_GEN:=en_US ISO-8859-1|en_US.UTF-8 UTF-8}
: ${GENTOO_TOOLS_WGETPASTE:=1}
: ${GENTOO_SYSTEM_TIMEZONE:=America/New_York}
: ${GENTOO_PORTAGE_NICENESS=19}
: ${GENTOO_PORTAGE_SCHEDULING_POLICY=batch}
: ${_CONF_GENTOO_INSTALLER_LIVE_PATH:=/run/root-volume}
: ${_CONF_GENTOO_INSTALLER_LIVE_OVERLAY_PATH:=/mnt/overlay}
: ${_CONF_GENTOO_INSTALLER_LIVE_COMPRESSION_TYPE:=zstd}
: ${GENTOO_ROOT_SQUASH_OUTPUT_FILE=$_CONF_APPLICATION_DATA_PATH/gentoo-root.img.$_CONF_GENTOO_INSTALLER_LIVE_COMPRESSION_TYPE}
: ${_CONF_GENTOO_INSTALLER_LIVE_USE_ENCRYPTION:=y}
: ${GENTOO_DRACUT_MODULES:="dmsquash-live"}
: ${_CONF_GENTOO_INSTALLER_UPDATE_EFI:=n}
: ${GENTOO_BOOT_LOADER_ARGS:="consoleblank=300 quiet"}
: ${BUSYBOX_CMDS:="awk basename cat cp dd df dirname dmesg find grep insmod losetup ln ls lsmod mkdir modprobe mount readlink rm sh sleep stat switch_root umount uname"}
: ${INIT_CMDS:="/usr/bin/busybox /usr/bin/cryptsetup /usr/bin/findfs /usr/bin/rsync /usr/bin/tar /usr/bin/udevadm /usr/lib/systemd/systemd-udevd"}
: ${OVERLAYFS_SIZE:=1073741824}
: ${INIT_COMPRESSION:=zstd}
: ${INIT_OUTPUT_FILE:=$_CONF_APPLICATION_DATA_PATH/initramfs.cpio.$INIT_COMPRESSION}
: ${INIT_COMPRESSION_CMD:="zstd --ultra"}
: ${INIT_REQUIRED_MODULES:="loop overlay squashfs usb_storage uas"}
: ${INIT_MODULE_PATHS:="crypto fs lib drivers/{block,ata,nvme,md} drivers/usb/{host,storage}"}
GENTOO_LIVE_DATA_FILE=$_CONF_GENTOO_INSTALLER_LIVE_PATH/data.tar.$_CONF_GENTOO_INSTALLER_LIVE_COMPRESSION_TYPE
GENTOO_LUKS_KEY_HEADER_PATH=/run/.luks-header
[ -n "$INTERACTIVE" ] && LUKS_OPTIONS="-q"
_include init live logging
trap _on_exit 0 1 2 3 4 6 15 EXIT INT
_INFO '### walterjwhite init ###'
_ _mount_filesystems
_ modules_${MODULES_IMPLEMENTATION}
_process_cmdline
_ _wait_for_device
_ _cryptsetup_open
_ _mount_root_volume
_ _ram
_ _overlay root
_WARN=1 _ _read_rw
_ _cleanup
_ _switch_root
