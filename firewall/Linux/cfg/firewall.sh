: ${_CONF_FIREWALL_LOCK_TIMEOUT:=60}
: ${_CONF_FIREWALL_LOCK_FILE:=/tmp/pfctl.lock}
: ${_CONF_FIREWALL_IP_BLOCK_ET:=https://rules.emergingthreats.net/blockrules/compromised-ips.txt https://rules.emergingthreats.net/fwrules/emerging-Block-IPs.txt}
: ${_CONF_FIREWALL_IP_BLOCK_PROVIDERS:=et firehol}
: ${_CONF_FIREWALL_TABLES_PATH:=/usr/local/etc/walterjwhite/firewall/dynamic}
: ${_CONF_FIREWALL_PARALLEL_WORKERS:=8}
: ${_CONF_FIREWALL_DNS_TIMEOUT:=1}
