#!/bin/sh
_jira_jira() {
  local _uri=$1
  shift
  curl -u "$conf_dev_jira_cli_login:$conf_dev_jira_cli_api_token" \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    "$@" \
    "$conf_dev_jira_cli_url/rest/api/3/$uri" | jq
}
_jira_assign() {
  _jira_get_ticket
  validation_require "$1" "jira account id: _jira_assign"
  local _assignee=$1
  shift
  local jira_account_id
  case $_assignee in
  unassign)
    jira_account_id=null
    ;;
  default)
    jira_account_id=-1
    ;;
  self)
    jira_account_id=$conf_dev_jira_cli_account_id
    ;;
  *)
    jira_account_id=$_assignee
    ;;
  esac
  _jira_jira "issue/$jira_ticket_id/assignee" \
    -X PUT \
    -d "{\"accountId\": \"$jira_account_id\"}"
  unset _assignee jira_account_id
}
_jira_create() {
  local _summary=$1
  local _description=$2
  local _issue_type=$3
  local jira_custom_fields
  if [ -n "$4" ]; then
    jira_custom_fields=",$4"
  fi
  _jira_jira "issue" \
    -X POST \
    -d "{\"fields\": {\"project\": {\"id\": \"$conf_dev_jira_cli_project\"}, \"summary\": \"$summary\", \"description\": \"$description\", \"issuetype\": {\"id\":\"$issue_type\"}$custom_fields}}"
}
_jira_comment() {
  _jira_get_ticket
  validation_require "$1" "Comment Body"
  _jira_jira "issue/$jira_ticket_id/comment" \
    -X POST \
    -d "{\"body\": {\"version\":1, \"type\":\"doc\", \"content\":[{\"type\":\"paragraph\", \"content\": [{\"type\": \"text\", \"text\": \"$1\"}]}]}}"
}
_jira_transition() {
  _jira_get_ticket
  local jira_transition_id=$(printf '%s\n' $conf_dev_jira_transitions | tr '|' '\n' | grep ":${1}$" | cut -f1 -d':')
  validation_require "$jira_transition_id" "transition_id _JIRA_TRANSITION [$conf_dev_jira_transitions] $1"
  _jira_jira "issue/$jira_ticket_id/transitions" \
    -X POST \
    -d "{\"transition\": {\"id\": \"$jira_transition_id\"}}"
}
_jira_get_ticket() {
  jira_ticket_id="$_CONSOLE_CONTEXT_ID"
  validation_require "$jira_ticket_id" "JIRA_TICKET_ID (_CONSOLE_CONTEXT_ID)"
}
