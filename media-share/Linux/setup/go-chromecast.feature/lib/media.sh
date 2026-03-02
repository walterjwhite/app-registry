#!/bin/sh
_media_find_directories() {
  local media_directory
  for media_directory in $(find $_MEDIA_DIRECTORY -type d | sort -V); do
    if find $media_directory -mindepth 1 -maxdepth 1 \( -name '*.jpg' -or -name '*.mp4' \) \( -type f -or -type l \) -print -quit | grep -cqm1 '.'; then
      printf '%s\n' $media_directory
    fi
  done
}
_media_find() {
  find "$1" -mindepth 1 -maxdepth 1 \( -type l -or -type f \) -name "*.$2" | sort -V
}
_media_find_images() {
  _media_find "$1" 'jpg'
}
_media_find_videos() {
  _media_find "$1" 'mp4'
}
_media_play_slideshow() {
  [ $(_media_find_images $1 | wc -l) -eq 0 ] && return 1
  log_detail "playing slideshow for: $1"
  go-chromecast -$conf_media_share_chromecast_id_flag $_CHROMECAST_ID slideshow --repeat=false $(_media_find_images $1) || log_warn "error playing slideshow for: $1"
}
_media_play_videos() {
  [ $(_media_find_videos $1 | wc -l) -eq 0 ] && return 1
  log_detail "playing videos for: $1"
  for f in $(_media_find_videos $1); do
    go-chromecast -$conf_media_share_chromecast_id_flag $_CHROMECAST_ID load $f || log_warn "error playing video: $f"
  done
}
