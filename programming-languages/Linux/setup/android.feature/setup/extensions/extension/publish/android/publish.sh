#!/bin/sh
_rclone_prune_stale_files() {
	log_warn "pruning stale files: $rclone_remote : $rclone_min_age"
	local rclone_options
	[ "$conf_log_level" -eq 0 ] && rclone_options="--dry-run"
	rclone delete $rclone_remote --min-age $rclone_min_age $rclone_options
}
_rclone_publish_all() {
	[ -n "$rclone_remote" ] && {
		_rclone_publish $($1)
		return
	}
}
_rclone_publish() {
	log_info "publishing artifacts -> $rclone_remote"
	local build_artifact
	for build_artifact in "$@"; do
		local build_artifact_filename=$(basename $build_artifact)
		rclone copy "$build_artifact" "$rclone_remote" || {
			log_warn "failed to publish artifact to: $rclone_remote/$build_artifact_filename"
			continue
		}
		log_info "published $build_artifact -> $rclone_remote/$build_artifact_filename"
	done
}
: ${conf_programming_languages_android_build_target:=Debug}
_android_build_artifacts() {
  find . -type f -name "*.apk"
}
_rclone_publish_all _android_build_artifacts
