#!/bin/env bash

if [[ ${EUID} -ne 0 ]]; then
	echo "This script must be run as root."
	exit
fi

VM=sandbox

VM_STATE=`virsh domstate $VM`
[ "$VM_STATE" == "running" ] && virsh destroy $VM

virsh undefine $VM
virsh define $VM.xml
virsh start $VM
