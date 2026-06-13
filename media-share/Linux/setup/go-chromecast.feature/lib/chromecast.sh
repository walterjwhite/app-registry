#!/bin/sh
_media_get_chromecast() {
  log_info "finding chromecast"
  local chromecasts=$(go-chromecast ls)
  if [ $(printf "$chromecasts\n" | wc -l) -gt 1 ]; then
    log_warn "select device"
    printf '%s\n' "$chromecasts"
    _stdin_read_if 'Enter chromecast id (exclude port number 8009)' _CHROMECAST_ID
  else
    _CHROMECAST_ID=$(printf "$chromecasts" | sed -e "s/^.*$conf_media_share_chromecast_id_name=\"//" -e 's/".*//')
  fi
  validation_require "$_CHROMECAST_ID" _CHROMECAST_ID
  log_detail "using chromecast: $_CHROMECAST_ID"
}
_media_chromecast_play() {
  for media_directory in $(_media_find_directories); do
    _media_play_slideshow "$media_directory"
    _media_play_videos "$media_directory"
  done
}
