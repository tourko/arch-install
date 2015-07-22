#!/bin/bash

if [[ ${EUID} -ne 0 ]]; then
	echo "This script must be run as root."
	exit
fi

# Get the path to this script
MY_PATH=`dirname "$0"`
MY_PATH=`( cd "$MY_PATH" && pwd )`

# Clean up after the last build
[ -d $MY_PATH/out ] && rm -rf $MY_PATH/out
[ -d $MY_PATH/work ] && rm -rf $MY_PATH/work

