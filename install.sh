#!/bin/bash

TIMEZONE=Europe/Copenhagen
USER=at

###########################
# Get the first SCSI disk #
###########################

# Major number for SCSI disk devices is 8
MAJOR_NUMBER=8
DISK=`lsblk --path --nodeps --noheadings --include ${MAJOR_NUMBER} --output=NAME | head -1`
if [ -z "$DISK" ]; then
  echo "!!! No SCSI disks found. Existing the instalation. !!!"
  exit
else
  echo ">>> Installing on '${DISK}'."
fi

##############################
# Delete existing partitions #
##############################

# Unmount existing partions
mount -l -t ext4 | grep "^${DISK}[[:digit:]]" | sort | awk '{print $1}' | while read dev
do
  echo ">>> Unmounting $dev"
  umount $dev
done

# Wipe out MBR and GPT
sgdisk --zap-all ${DISK}
sgdisk --print $DISK | egrep '^[[:blank:]]{0,3}[[:digit:]]' | awk '{print $1}' | while read num
do
  echo ">>> Deleting partition #$num"
  sgdisk --delete $num $DISK
  sleep 1
done

#################
# Set GPT label #
#################
echo ">>> Create a new empty GPT"
sgdisk -g --clear $DISK


#####################
# Create partitions #
#####################

# Create a 1 MiB BIOS partition for GRUB core.img
echo ">>> Creating BIOS partition"
sgdisk --new 1:2048:4095 --change-name 1:"BIOS" --typecode 1:EF02 $DISK
sleep 1

# Create a 64 MiB partion for /boot
echo ">>> Creating BOOT partition"
sgdisk --new 2:4096:+64M --change-name 2:"BOOT" --typecode 2:8300 $DISK
sleep 1

# Create a partition for / that spans the remaining disk
echo ">>> Creating ROOT partition"
START=`sgdisk --first-aligned-in-largest $DISK`
END=`sgdisk --end-of-largest $DISK`
sgdisk -n 3:$START:$END -c 3:"ROOT" -t 3:8300 $DISK
sleep 1

# Display the partition table
sgdisk --print $DISK

######################
# Create filesystems #
######################

# Create ext4 filesystem on /dev/sda1 partition (/boot)
echo ">>> Creating file system on /boot"
mkfs.ext4 -L BOOT ${DISK}2

# Create ext4 filesystem on /dev/sda3 partition (/)
echo ">>> Creating filesystem on /"
mkfs.ext4 -L ROOT ${DISK}3

#####################
# Mount filesystems #
#####################

# Mount /dev/sda3 partition (/)
echo ">>> Mounting /dev/sda3 (/)"
mount ${DISK}3 /mnt

# Create mount point for /boot partion
mkdir /mnt/boot

# Mount /dev/sda2 partition (/boot)
echo ">>> Mounting /dev/sda2 (/boot)"
mount ${DISK}2 /mnt/boot

###########################
# Install the base system #
###########################
echo ">>> Installing the base system"
pacstrap /mnt base

#####################
# Generate an fstab #
#####################
echo ">>> Generating an fstab"
genfstab -L -p /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab

#####################
# Copy config files #
#####################
echo ">>> Copying config files"
cp /tmp/config.tar.bz2 /mnt

##############################
# Chroot into the new system #
##############################
echo ">>> chroot into the new system"
arch-chroot /mnt /bin/env PS1="(chroot) $PS1" TIMEZONE=$TIMEZONE USER=$USER DISK=$DISK /bin/bash

########################
# Extract config files #
########################
mv /config.tar.bz2 /tmp
tar -xvjf /tmp/config.tar.bz2 -C /tmp
CONFIG=/tmp/config

############################
# Install usefull packages #
############################
echo ">>> Installing optional packages"
pacman --noconfirm --quiet -S patch

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
pacman --noconfirm --quiet -S grub
grub-install --target=i386-pc --recheck $DISK
grub-mkconfig -o /boot/grub/grub.cfg

###############
# Enable DHCP #
###############
echo ">>> Enabling DHCP"
systemctl enable dhcpcd.service

#############################
# Install and configure SSH #
#############################
echo ">>> Installing and configuering openssh"
pacman --noconfirm --quiet -S openssh
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
pacman --noconfirm --quiet -S bash-completion

#######################
# Configure /etc/skel #
#######################
echo ">>> Configuring /etc/skel"
cp $CONFIG/etc/skel/.bash_profile /etc/skel/.bash_profile

##############################
# Install and configure sudo #
##############################
echo ">>> Installing and configuring sudo"
pacman --noconfirm --quiet -S sudo
cp $CONFIG/etc/sudoers /etc/sudoers

####################
# Install software #
####################
echo ">>> Installing extra software"
pacman --noconfirm --quiet -S vim-minimal
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
exit

#####################################
# Unmount the partitions and reboot #
#####################################
umount /mnt/{boot,}

##########
# Reboot #
##########
echo ">>> Rebooting"
reboot

exit
