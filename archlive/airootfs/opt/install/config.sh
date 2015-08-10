#!/bin/env sh

########################
# Extract config files #
########################
mv /rootfs.tar.bz2 /tmp
tar -xvjf /tmp/rootfs.tar.bz2 -C /tmp
CONFIG=/tmp/rootfs

################################
# Synchronize package database #
################################
pacman -Sy

##########################
# Write to /etc/hostname #
##########################
echo ">>> Setting hostname"
cp $CONFIG/etc/hostname /etc/hostname

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
cp $CONFIG/etc/locale.gen /etc/locale.gen
locale-gen
cp $CONFIG/etc/locale.conf /etc/locale.conf
cp $CONFIG/etc/vconsole.conf /etc/vconsole.conf

########################
# Lock root's password #
########################
echo ">>> Locking root password"
passwd -l root

####################
# Configure pacman #
####################
echo ">>> Patching /etc/pacman.conf"
patch /etc/pacman.conf $CONFIG/etc/pacman.conf.diff

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

#################
# Configure SSH #
#################
echo ">>> Configuering openssh"
cp $CONFIG/etc/ssh/sshd_config /etc/ssh/sshd_config

###############
# Enable SSHD #
###############
echo ">>> Enabling SSHD"
systemctl enable sshd.service

##########################
# Configure shell colors #
##########################
echo ">>> Copying DIR_COLOR to /etc"
cp $CONFIG/etc/DIR_COLORS /etc/DIR_COLORS

##################
# Configure bash #
##################
echo ">>> Copying bash.bashrc to /etc"
cp $CONFIG/etc/bash.bashrc /etc/bash.bashrc

#######################
# Configure /etc/skel #
#######################
echo ">>> Configuring /etc/skel"
cp $CONFIG/etc/skel/.bash_profile /etc/skel/.bash_profile

##################
# Configure sudo #
##################
echo ">>> Configuring sudo"
cp $CONFIG/etc/sudoers /etc/sudoers

# Add vimrc to /etc
cp $CONFIG/etc/vimrc /etc/vimrc

############
# Add user #
############
echo ">>> Adding user '$USER'"
useradd --gid users --groups wheel --create-home $USER
# Reset the password
passwd -d $USER
# Remove .bashrc
rm /home/$USER/.bashrc

###############
# Exit chroot #
###############
echo ">>> Exiting chroot"
exit

