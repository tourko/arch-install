#!/bin/env sh

if [[ ${EUID} -ne 0 ]]; then
	echo "This script must be run as root."
	exit
fi

# Get the path to this script
MY_PATH=`dirname "$0"`
MY_PATH=`( cd "$MY_PATH" && pwd )`

REPO_PATH="$MY_PATH/airootfs/opt/install/repo"

# Clean up install repo
[ -d $REPO_PATH ] && rm -f $REPO_PATH/*
