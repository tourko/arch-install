#!/bin/env sh

if [[ ${EUID} -ne 0 ]]; then
	echo "This script must be run as root."
	exit
fi

# Get all packages and their dependecies for 'base' group
PACKAGES=$(for package in `pacman -Sp --print-format %n base`
do
	pactree -lu $package
done | sort | uniq)

# Update pacman database
pacman -Sy

# Get the path to this script
MY_PATH=`dirname "$0"`
MY_PATH=`( cd "$MY_PATH" && pwd )`

# Create repo directory if it does not exits
REPO_PATH="$MY_PATH/airootfs/opt/install/repo"
[ -d $REPO_PATH ] !! mkdir $REPO_PATH

# Dowload packages
for package in $PACKAGES
do
	pacman --noconfirm --cachedir $REPO_PATH  -Sw $package
done

# Build repository database
repo-add -n $REPO_PATH/repo.db.tar.gz $REPO_PATH/*.pkg.tar.xz
