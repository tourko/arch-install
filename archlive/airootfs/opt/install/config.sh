#!/bin/env sh

########################
# Extract config files #
########################
echo ">>> Installing rootfs overlay"
mv /rootfs.tar.bz2 /tmp
tar -xmvjf /tmp/rootfs.tar.bz2 -C / --no-overwrite-dir

################################
# Synchronize package database #
################################
pacman -Sy

#################
# Set time zone #
#################
echo ">>> Setting time zone to $TIMEZONE"
rm -f /etc/localtime
ln -s /usr/share/zoneinfo/$TIMEZONE /etc/localtime

####################
# Configure locale #
####################
echo ">>> Configureing locale"
locale-gen

############################
# Wipe out root's password #
############################
echo ">>> Wiping out root password"
passwd -d root

#######################################
# Install and configure a boot loader #
#######################################
echo ">>> Installing GRUB"
grub-install --target=i386-pc --recheck $DISK
grub-mkconfig -o /boot/grub/grub.cfg

###############
# Enable DHCP #
###############
echo ">>> Enabling DHCP"
systemctl enable dhcpcd.service

###############
# Enable SSHD #
###############
echo ">>> Enabling SSHD"
systemctl enable sshd.service

###############
# Exit chroot #
###############
echo ">>> Exiting chroot"
exit

