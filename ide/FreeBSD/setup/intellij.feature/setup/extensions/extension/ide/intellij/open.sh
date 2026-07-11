#!/bin/sh
JAVA_HOME=$conf_dev_java_ide_java_home $conf_dev_intellij_ide $_IDE_PROJECT >/dev/null 2>&1 &
