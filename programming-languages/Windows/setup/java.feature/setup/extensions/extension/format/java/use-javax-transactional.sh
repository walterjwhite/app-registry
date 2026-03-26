#!/bin/sh
_extension_find_default -exec $GNU_SED -i 's/com.google.inject.persist.Transactional/jakarta.transaction.Transactional/' {} +
