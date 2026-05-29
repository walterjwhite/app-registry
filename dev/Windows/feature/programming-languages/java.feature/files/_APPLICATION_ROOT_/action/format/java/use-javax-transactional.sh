#!/bin/sh
_APPLICATION_NAME=dev
_EXEC_CMD="$_CONF_GNU_SED -i s/com.google.inject.persist.Transactional/jakarta.transaction.Transactional/ {} +"
