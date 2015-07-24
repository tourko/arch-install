#!/bin/env bash

VM=sandbox

VM_STATE=`virsh --connect qemu:///system domstate $VM`
[ "$VM_STATE" == "running" ] && virsh --connect qemu:///system destroy $VM

virsh --connect qemu:///system undefine $VM

sudo rm /tmp/archlinux.iso
cp ../archlive/out/archlinux.iso /tmp

sudo rm /tmp/${VM}.img
dd if=/dev/zero of=/tmp/${VM}.img bs=1G count=2

virsh --connect qemu:///system define $VM.xml
virsh --connect qemu:///system start $VM
