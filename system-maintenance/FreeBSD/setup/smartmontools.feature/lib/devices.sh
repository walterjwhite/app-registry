#!/bin/sh
_smartmontools_get_devices() {
  geom disk list | grep Name | cut -f2 -d':' | sed -e 's/ //' -e 's/^/\/dev\///'
}
