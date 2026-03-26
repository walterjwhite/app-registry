#!/bin/sh
for XML_FILE in $(_extension_find_default); do
  xmllint --format "$XML_FILE" -o "$XML_FILE"
done
