#!/bin/sh
_lines_get_extensions() {
  _name_pattern="*" _extension_find_default_files | sed -e "s/^.*\.//" |
    $GNU_GREP -P "^[a-zA-Z][\w]{1,3}$" |
    sort -u | tr '\n' ' '
}
for _file_type in $(_lines_get_extensions); do
  _name_pattern="*.$_file_type" _extension_find_default_files -exec wc -l {} + |
    grep total | sed -e "s/total/total ($_file_type)/" -e "s/^[ \t]*/$_LOG_INDENT/"
done
