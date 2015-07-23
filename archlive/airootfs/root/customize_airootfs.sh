#!/bin/bash

set -e -u

sed -i 's/#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
locale-gen

ln -sf /usr/share/zoneinfo/UTC /etc/localtime

chmod 700 /root

sed -i "s/#Server/Server/g" /etc/pacman.d/mirrorlist
sed -i 's/#\(Storage=\)auto/\1volatile/' /etc/systemd/journald.conf

# Permit root login via SSH with empty password
sed -i 's/#\(PermitRootLogin[[:space:]]\+\)no/\1yes/' /etc/ssh/sshd_config
sed -i 's/#\(PermitEmptyPasswords[[:space:]]\+\)no/\1yes/' /etc/ssh/sshd_config

systemctl enable pacman-init.service choose-mirror.service
systemctl enable sshd.service
systemctl set-default multi-user.target
