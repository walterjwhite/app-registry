#!/bin/sh
set -a
_APPLICATION_NAME=gentoo-installer
_include() {
	local include_file
	for include_file in "$@"; do
		[ -f $HOME/.config/walterjwhite/$include_file ] && . $HOME/.config/walterjwhite/$include_file
	done
}
_() {
	_detail "### $*"
	"$@" || {
		_warn "Error: $?"
		[ -n "$_WARN" ] && return
		exec /bin/sh
		return 1
	}
	_info "    completed: $*"
}
_mount_filesystems() {
	mount -t proc proc /proc
	mount -t sysfs sysfs /sys
	mount -t devtmpfs devtmpfs /dev
	mount -t tmpfs -o rw,nosuid,nodev,relatime,mode=755 none /run
}
_modules_udev() {
	/usr/lib/systemd/systemd-udevd --daemon --resolve-names=never
	udevadm trigger
	udevadm settle
}
_modules_host() {
	modprobe -a KERNEL_MODULES
	return 0
}
_process_cmdline() {
	local overlayfs_size=$(cat /proc/cmdline | tr ' ' '\n' | grep overlayfs.size | cut -f2 -d=)
	[ -n "$overlayfs_size" ] && OVERLAYFS_SIZE=$overlayfs_size
	LUKS_DEVICE_UUID=$(cat /proc/cmdline | tr ' ' '\n' | grep luks.uuid | cut -f2 -d=)
	cat /proc/cmdline | grep -qm1 'init.debug' >/dev/null 2>&1 && set -x
}
_cryptsetup_open() {
	local tries=3
	while [ $tries -gt 0 ]; do
		LUKS_DEVICE_PATH=$(findfs UUID=$LUKS_DEVICE_UUID)
		[ -n "$LUKS_DEVICE_PATH" ] && break
		sleep 3
		tries=$(($tries - 1))
	done
	cryptsetup luksOpen $LUKS_DEVICE_PATH luks-$LUKS_DEVICE_UUID
}
_mount_root_volume() {
	mkdir -p /run/root-volume
	mount -o ro /dev/mapper/luks-$LUKS_DEVICE_UUID /run/root-volume
}
_ram() {
	local system_memory=$(cat /proc/meminfo | grep MemTotal | awk {'print$2'})
	system_memory=$(($system_memory * 1024))
	local root_imgsize=$(stat -c %s /run/root-volume/root-squashfs.img)
	local memory_required=$(($root_imgsize + $OVERLAYFS_SIZE))
	[ $memory_required -ge $system_memory ] && {
		_detail "System has insuffient memory to run in memory"
		VOLUME_PATH=root-volume
		return
	}
	_detail "Resizing /run volume to match size of images: [$root_imgsize] [$system_memory]"
	mount -o remount,size=$root_imgsize /run
	mkdir -p /run/root-image
	_detail 'Copying image into memory'
	rsync -h --info=progress /run/root-volume/root-squashfs.img /run/root-image/root-squashfs.img
	_detail 'Copied image into memory'
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
	_CONF_GENTOO_INSTALLER_LIVE_PATH=/run/root-volume /mnt/root-rw/usr/local/bin/read-rw mnt/root-rw
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
	_detail "Changes are visible @ /mnt/overlay"
	exec switch_root /mnt/root-rw /sbin/init
}
_init_logging() {
	[ -n "$_LOGFILE" ] && _set_logfile "$_LOGFILE"
	case $_CONF_LOG_LOG_LEVEL in
	0)
		local logfile=$(_mktemp debug)
		_warn "Writing debug contents to: $logfile"
		_set_logfile "$logfile"
		set -x
		;;
	esac
}
_set_logfile() {
	[ -z "$1" ] && return 1
	_LOGFILE=$1
	mkdir -p $(dirname $1)
	_reset_indent
	[ -n "$_CHILD_LOG" ] || exec 3>&1 4>&2
	exec >>$_LOGFILE 2>&1
	[ -z "$_PRESERVE_LOG" ] && [ -z "$_CHILD_LOG" ] && truncate -s 0 $1 >/dev/null 2>&1
}
_reset_logging() {
	[ !-t 3 ] && return
	[ -n "$_CHILD_LOG" ] && return
	exec 1>&3
	exec 2>&4
	exec 3>&-
	exec 4>&-
}
_warn() {
	_print_log 3 WRN "$_CONF_LOG_C_WRN" "$_CONF_LOG_BEEP_WRN" "$1"
}
_info() {
	_print_log 2 INF "$_CONF_LOG_C_INFO" "$_CONF_LOG_BEEP_INFO" "$1"
}
_detail() {
	_print_log 2 DTL "$_CONF_LOG_C_DETAIL" "$_CONF_LOG_BEEP_DETAIL" "$1"
}
_debug() {
	_print_log 1 DBG "$_CONF_LOG_C_DEBUG" "$_CONF_LOG_BEEP_DEBUG" "($$) $1"
}
_log() {
	:
}
_colorize_text() {
	printf '\033[%s%s\033[0m' "$1" "$2"
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
	[ $1 -lt $_CONF_LOG_LOG_LEVEL ] && return
	[ -n "$_LOGGING_CONTEXT" ] && message="$_LOGGING_CONTEXT - $message"
	local _message_date_time=$(date +"$_CONF_LOG_DATE_FORMAT")
	if [ $_BACKGROUNDED ] && [ $_OPTN_INSTALL_BACKGROUND_NOTIFICATION_METHOD ]; then
		$_OPTN_INSTALL_BACKGROUND_NOTIFICATION_METHOD "$2" "$_message" &
	fi
	[ -n "$4" ] && _beep "$4"
	_log_to_file "$2" "$_message_date_time" "${_LOG_INDENT}$message"
	_log_to_console "$3" "$2" "$_message_date_time" "${_LOG_INDENT}$message"
	[ -z "$INTERACTIVE" ] && _syslog "$message"
	return 0
}
_add_logging_context() {
	[ -z "$1" ] && return 1
	if [ -z "$_LOGGING_CONTEXT" ]; then
		_LOGGING_CONTEXT="$1"
		return
	fi
	_LOGGING_CONTEXT="$_LOGGING_CONTEXT.$1"
}
_remove_logging_context() {
	[ -z "$_LOGGING_CONTEXT" ] && return 1
	case $_LOGGING_CONTEXT in
	*.*)
		_LOGGING_CONTEXT=$(printf '%s' "$_LOGGING_CONTEXT" | sed 's/\.[a-z0-9 _-]*$//')
		;;
	*)
		unset _LOGGING_CONTEXT
		;;
	esac
}
_increase_indent() {
	_LOG_INDENT="$_LOG_INDENT${_CONF_LOG_INDENT}"
}
_decrease_indent() {
	_LOG_INDENT=$(printf '%s' "$_LOG_INDENT" | sed -e "s/${_CONF_LOG_INDENT}$//")
	[ ${#_LOG_INDENT} -eq 0 ] && _reset_indent
}
_reset_indent() {
	unset _LOG_INDENT
}
_log_to_file() {
	[ -z "$_LOGFILE" ] && return
	if [ $_CONF_LOG_AUDIT -gt 0 ]; then
		printf '%s %s %s\n' "$1" "$2" "$3" >>$_LOGFILE
		return
	fi
	printf '%s\n' "$3" >>$_LOGFILE
}
_log_to_console() {
	local stderr=2
	[ ! -t $stderr ] && stderr=4
	[ ! -t $stderr ] && return
	if [ $_CONF_LOG_AUDIT -gt 0 ]; then
		printf >&$stderr '\033[%s%s \033[0m%s %s\n' "$1" "$2" "$3" "$4"
		return
	fi
	printf >&$stderr '\033[%s%s \033[0m\n' "$1" "$4"
}
_log_app() {
	_debug "$_APPLICATION_NAME:$_APPLICATION_CMD - $1 ($$)"
}
_include ./init
_include ./live
_include logging
: ${MODULES_IMPLEMENTATION:=host}
: ${_CONF_GENTOO_INSTALLER_LIVE_PATH:=/mnt/live}
: ${_CONF_GENTOO_INSTALLER_LIVE_OVERLAY_PATH:=/mnt/overlay}
: ${_CONF_GENTOO_INSTALLER_LIVE_COMPRESSION_TYPE:=zstd}
: ${_CONF_GENTOO_INSTALLER_LIVE_USE_ENCRYPTION:=y}
: ${GENTOO_DRACUT_MODULES:="dmsquash-live"}
: ${_CONF_GENTOO_INSTALLER_UPDATE_EFI:=n}
: ${GENTOO_BOOT_LOADER_ARGS:="consoleblank=300 quiet"}
: ${BUSYBOX_CMDS:="basename cat cp dd df dirname dmesg find grep insmod losetup ln ls lsmod mkdir modprobe mount readlink rm sh sleep stat switch_root umount uname"}
: ${INIT_CMDS:="/usr/bin/busybox /usr/bin/cryptsetup /usr/bin/findfs /usr/bin/rsync /usr/bin/tar /usr/bin/udevadm /usr/lib/systemd/systemd-udevd"}
: ${OVERLAYFS_SIZE:=1073741824}
: ${INIT_WORK_DIR:=/tmp/init}
: ${INIT_COMPRESSION:=zstd}
: ${INIT_COMPRESSION_CMD:="zstd --ultra -o"}
: ${INIT_OUTPUT_FILE:=/tmp/initramfs.cpio.$INIT_COMPRESSION}
: ${INIT_REQUIRED_MODULES:="loop overlay squashfs usb_storage uas"}
: ${INIT_MODULE_PATHS:="crypto fs lib drivers/{block,ata,nvme,md} drivers/usb/{host,storage}"}
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
: ${_CONF_LOG_AUDIT:=0}
: ${_CONF_LOG_LOG_LEVEL:=2}
: ${_CONF_LOG_INDENT:="  "}
: ${_CONF_LOG_CONF_VALIDATION_FUNCTION:=_warn}
: ${_CONF_LOG_WAITER_LEVEL:=_debug}
: ${_CONF_LOG_FEATURE_TIMEOUT_ERROR_LEVEL:=warn}
: ${_CONF_LOG_LONG_RUNNING_CMD:=30}
: ${_CONF_LOG_LONG_RUNNING_CMD_LINES:=1000}
[ -t 0 ] && INTERACTIVE=1
_info '### walterjwhite init ###'
_ _mount_filesystems
_ _modules_${MODULES_IMPLEMENTATION}
_process_cmdline
_ _cryptsetup_open
_ _mount_root_volume
_ _ram
_ _overlay root
_WARN=1 _ _read_rw
_ _cleanup
_ _switch_root
