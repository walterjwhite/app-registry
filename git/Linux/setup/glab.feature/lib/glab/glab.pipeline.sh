#!/bin/sh
_glab_pipeline_status() {
  local _glab_pipeline_status=$(glab pipeline status | grep $glab_pipeline_stage | awk {'print$1'} | tr -d '(' | tr -d ')')
  validation_require "$_glab_pipeline_status" _glab_pipeline_status
}
_glab_pipeline_status_is_terminal() {
  case $_glab_pipeline_status in
  running | pending | created | waiting_for_resource | preparing | pending | manual | scheduled)
    return 1
    ;;
  *)
    return 0
    ;;
  esac
}
_glab_pipeline_status_isexit_with_success() {
  case $_glab_pipeline_status in
  success)
    return 0
    ;;
  *)
    return 1
    ;;
  esac
}
_glab_pipeline_status_is_waiting_manual() {
  case $_glab_pipeline_status in
  manual)
    return 0
    ;;
  *)
    return 1
    ;;
  esac
}
