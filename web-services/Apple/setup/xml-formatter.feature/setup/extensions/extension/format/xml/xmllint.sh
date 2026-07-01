#!/bin/sh
for XML_FILE in $(_extension_find_default); do
  xmllint --format "$XML_FILE" -o "$XML_FILE"
done
for xml_name_pattern in atom html xhtml rss svg; do
  for HTML_FILE in $(_extension_find_default); do
    xmllint --html --xmlout --format "$HTML_FILE" -o "$HTML_FILE"
  done
done
