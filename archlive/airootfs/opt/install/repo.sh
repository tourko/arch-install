#!/bin/bash

if [[ ${EUID} -ne 0 ]]; then
	echo "This script must be run as root."
	exit
fi

# Get the name of the script
SCRIPTNAME=${0##*/}

# Get the path to this script
MY_PATH=`dirname "$0"`
MY_PATH=`( cd "${MY_PATH}" && pwd )`

# Defaul action is to build a repository
OPT_ACTION=BUILD

# Path to the repository
REPO_PATH="${MY_PATH}/repo"

show_usage()
{
cat << EOB
Usage: ${SCRIPTNAME} [OPTIONS]

Options:
	--help	: This help text
	--build	: Build repository
	--clean	: Clean repository
EOB
}

parse_options()
{
	while test -n "$1"; do
		# Convert an argument to a lower case
		local lc_arg=`echo -n $1 | tr "[:upper:]" "[:lower:]"`
		case $lc_arg in
			--help)
				show_usage
				exit 0
				;;
			--build)
				OPT_ACTION=BUILD
				;;
			--clean)
				OPT_ACTION=CLEAN
				;;
			*)
				echo -e "\nUnknown argument '$lc_arg'\n"
				show_usage
				exit 1
				;;
		esac

		# Move to the next argument
		shift
	done
}

build_repo()
{
	# Add packages and their dependencies from repo.list
	local PACKAGES=$(while read -r line
	do
		pactree -lu $line
	done < <(grep -v "^[[:space:]]*$" $MY_PATH/repo.list))

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
	[ -d ${REPO_PATH} ] || mkdir ${REPO_PATH}

	# Dowload packages
	for package in ${PACKAGES}
	do
		pacman --noconfirm --cachedir ${REPO_PATH}  -Sw ${package}
	done

	# Build repository database
	repo-add -n ${REPO_PATH}/repo.db.tar.gz ${REPO_PATH}/*.pkg.tar.xz
}

clean_repo()
{
	echo "Cleaning repository."
	[ -d ${REPO_PATH} ] && rm -f ${REPO_PATH}/*
}

parse_options ${@}

case ${OPT_ACTION} in
	BUILD)
		build_repo
		;;
	CLEAN)
		clean_repo
		;;
esac

