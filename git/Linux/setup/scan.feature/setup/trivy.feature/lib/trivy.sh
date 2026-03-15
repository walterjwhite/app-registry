#!/bin/sh
_trivy_scan() {
  exit_defer _trivy_cleanup
  trivy -q "$@" >"$report_path.new"
  if [ -e "$report_path" ]; then
    log_detail "comparing with existing scan"
    diff "$report_path.new" "$report_path" >/dev/null && {
      log_info "no changes detected"
      rm -f "$report_path.new"
      return
    }
  else
    log_warn "no existing scan found"
    [ $(wc -l <"$report_path.new") -eq 0 ] && {
      log_info "no findings found"
      rm -f "$report_path.new"
      return
    }
    cat "$report_path.new"
  fi
  _stdin_continue_if "do you accept the findings above?" "Y/n" || exit_with_error "user aborted"
  log_info "user accepted scan findings - saving scan to $report_path"
  mv "$report_path.new" "$report_path"
}
_trivy_cleanup() {
  find /tmp -maxdepth 1 -mindepth 1 -name 'analyzer-fs-*' -exec rm -rf {} + 2>/dev/null
}
