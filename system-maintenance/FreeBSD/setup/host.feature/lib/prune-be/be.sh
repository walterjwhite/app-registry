#!/bin/sh
_prune_be_destroy() {
  log_warn "destroying BE $_be_name - created $_be_cr_dt ($_be_age_human)"
  beadm destroy -F $_be_name 2>&1 | sed -e 's/^/  /'
}
_prune_be_by_age() {
  beadm list -H | $GNU_GREP -Pv '(N|R)' | while read be_dtl; do
    _prune_be_details
    if [ $_be_age -gt $conf_system_maintenance_be_expiration_period ]; then
      _prune_be_destroy
    else
      log_debug "retaining snapshot: $_be_name $_be_cr_dt $_be_age_human"
    fi
    _be_cleanup
  done
}
_prune_be_by_number() {
  if [ -z "$conf_system_maintenance_max_be_to_keep" ]; then
    return
  fi
  be_dtl=""
  beadm list -H | $GNU_GREP -Pv '^.*[\s]+(N|R)' | tail -r | tail -n +$conf_system_maintenance_max_be_to_keep | tail -r | while read be_dtl; do
    _prune_be_details
    _prune_be_destroy
    _be_cleanup
  done
}
_prune_be_details() {
  _be_name=$(printf '%s' "$be_dtl" | awk '{print$1}')
  _be_cr_dt=$(printf '%s' "$be_dtl" | awk '{print$5" "$6}')
  be_cr_dt_epoch=$(date -j -f "%Y-%m-%d %H:%M:%S" "$_be_cr_dt:00" "+%s")
  _be_age=$(($_current_epoch_time - $be_cr_dt_epoch))
  _time_seconds_to_human_readable $_be_age
  _be_age_human=$_HUMAN_READABLE_TIME
  unset _HUMAN_READABLE_TIME
}
_be_cleanup() {
  unset _be_name _be_cr_dt _be_age _be_age_human
}
