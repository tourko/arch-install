#!/usr/bin/env bash

#
# Copyright © Andrey Tourkó (at@napatech.com / tourko@gmail.com)
# Copyright © 2016. Napatech A/S (www.napatech.com)
#

# Script name
SCRIPT=`basename ${BASH_SOURCE[0]}`

# Path to this script
MY_PATH=$(cd "$(dirname --zero "$0")" && pwd)

# CD image
CD="$MY_PATH/out/archlinux.iso"

# Disk image
DISK=$MY_PATH/disk.img

# PID_FILE
PID_FILE='.qemu.1.pid'

# If PID_FILE exist, kill the process with the PID in the file
if [ -f $PID_FILE ]
then
	PID=$(cat $PID_FILE)
	ps --no-headers -p $PID > /dev/null && kill $PID
	rm $PID_FILE
fi

# Create raw disk image if it doesn't exist
[ -f "$DISK" ] || qemu-img create -f raw "$DISK" 4G

qemu-system-x86_64 \
	-name arch \
	-machine pc,accel=kvm \
	-cpu host -smp 8 -m 4G \
	-localtime \
	-netdev bridge,id=nic0,br=virtbr0 -device virtio-net-pci,netdev=nic0,id=net0,mac=1E:41:54:00:00:02 \
	-object iothread,id=iothread0 \
	-drive if=none,id=drive0,format=raw,media=disk,file="$DISK" \
	-device virtio-blk,drive=drive0,scsi=off,config-wce=off,iothread=iothread0 \
	-cdrom "$CD" \
	-boot order=c \
	-vnc :1,password \
	-qmp-pretty tcp:127.0.0.1:4444,server,nowait \
	-daemonize -pidfile $PID_FILE

sleep 1

nc -c -t 127.0.0.1 4444 <<EOF
{ "execute": "qmp_capabilities" }
{ "execute": "set_password", "arguments": { "protocol": "vnc", "password": "" } }
EOF
