#!/bin/sh
_APPLICATION_NAME=status
if [ -z "$_CONF_STATUS_ELASTICSEARCH_HOST" ]; then
	_FEATURE_ELASTICSEARCH_DISABLED=1
fi
elasticsearch() {
	local index
	for index in $(curl $_CONF_STATUS_ELASTICSEARCH_HOST/_cat/indices -H 'Content-Type: application/json' -s | awk {'print$3'} | grep -v '^\.'); do
		_elasticsearch_prune_old_data $index
	done
}
_elasticsearch_prune_old_data() {
	_INFO "Attempting to delete data > $_CONF_STATUS_ELASTICSEARCH_RETENTION_PERIOD from $1"
	_ curl -s -X POST $_CONF_SYSTEM_MAINTENANCE_ELASTICSEARCH_HOST/$index/_delete_by_query -d"{\"query\": {\"range\": {\"@timestamp\": {\"lte\": \"now-$_CONF_STATUS_ELASTICSEARCH_RETENTION_PERIOD\"}}}}" -H 'Content-Type: application/json'
}
