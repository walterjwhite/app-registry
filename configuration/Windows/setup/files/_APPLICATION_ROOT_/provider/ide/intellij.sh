#!/bin/sh
_conf_intellij_get_directory() {
  case $_ACTION in
  backup)
    provider_path=$(find "$1" -maxdepth 1 -type d -name '*Idea*' 2>/dev/null)
    if [ $? -gt 0 ]; then
      unset provider_path
      return
    fi
    printf '%s\n' "$provider_path" >$APP_DATA_PATH/$provider_name/.version
    ;;
  restore)
    provider_path=$(head -1 $APP_DATA_PATH/$provider_name/.version 2>/dev/null)
    ;;
  esac
  provider_path_is_dir=1
  provider_include="keymaps options idea.key"
  provider_no_root_user=1
}
case $APP_PLATFORM_PLATFORM in
Windows)
  _conf_intellij_get_directory ~/AppData/IntelliJ
  ;;
Apple)
  _conf_intellij_get_directory ~/Library/"Application Support"/JetBrains
  ;;
Linux | FreeBSD)
  _conf_intellij_get_directory ~/.config/JetBrains
  ;;
esac
_configuration_intellij_export_post() {
  find $configuration_tmpdir/$provider_name -type f \( \
    ! -path '*/options/ide.general.xml' -and \
    ! -path '*/options/shared-indexes.xml' -and \
    ! -path '*/options/console-font.xml' -and \
    ! -path '*/options/debugger.xml' -and \
    ! -path '*/options/colors.scheme.xml' -and \
    ! -path '*/options/laf.xml' -and \
    ! -path '*/options/editor-font.xml' -and \
    ! -path '*/options/settingsSync.xml' -and \
    ! -path '*/options/runner.layout.xml' -and \
    ! -path '*/options/freebsd/keymap.xml' -and \
    ! -path '*/options/keymapFlags.xml' -and \
    ! -path '*/options/vcs.xml' -and \
    ! -path '*/options/diff.xml' -and \
    ! -path '*/options/acceptedLanguageLevels.xml' -and \
    ! -path '*/keymaps/XWin copy.xml' \) -exec rm -f {} +
}
