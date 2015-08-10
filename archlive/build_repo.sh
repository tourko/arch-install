#!/bin/bash

if [[ ${EUID} -ne 0 ]]; then
	echo "This script must be run as root."
	exit
fi

# Get the path to this script
MY_PATH=`dirname "$0"`
MY_PATH=`( cd "$MY_PATH" && pwd )`

# Add packages and their dependencies from repo.list
PACKAGES=$(while read -r line
do
	pactree -lu $line
done < <(grep -v "^[[:space:]]*$" $MY_PATH/airootfs/opt/install/repo.list))

# Add packages and their dependecies from 'base' group
PACKAGES+=$(for package in `pacman -Sp --print-format %n base`
do
	pactree -lu $package
done)

PACKAGES=$(printf "%s\n" ${PACKAGES[@]} | sort -n | uniq)

echo "Packets to be added to the repo:"
echo $PACKAGES

# Update pacman database
pacman -Sy

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
