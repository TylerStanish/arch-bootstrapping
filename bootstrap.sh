#!/bin/bash
function print_error_message() {
  echo 'failed...'
}
trap 'print_error_message' ERR

read -p "Enter block device to install onto: " location
read -p "Enter block device partition prefix (e.g. /dev/nvme0n1p where partitions are like /dev/nvme0n1p1):" partition_prefix
read -p "Enter swap space in gigabytes" swap_size

timedatectl set-ntp true

# BEGIN PARTITIONING
echo "
g
n


+512M
Y
n


-${swap_size}G
Y
n



Y
t
1
1
t
2
24
t
3
19
w
"

mkfs.fat ${partition_prefix}1
mkfs.ext4 ${partition_prefix}2
mkswap ${partition_prefix}3
swapon ${partition_prefix}3

mkdir /mnt/efi
mount ${partition_prefix}1 /mnt/efi
mount ${partition_prefix}2 /mnt


# Set mirrors
# For now, use the Purdue Linux Users Group mirror first!
printf \
  "%s\n%s\n" \
  "Server = http://plug-mirror.rcac.purdue.edu/archlinux/\$repo/os/\$arch" \
  "$(cat /etc/pacman.d/mirrorlist)" \
  > /etc/pacman.d/mirrorlist

# later on...
pacstrap /mnt base base-devel linux linux-firmware vim man-db \
  man-pages texinfo dhcp iputils net-tools sudo \
  dialog netctl grub efibootmgr

genfstab -U /mnt >> /mnt/etc/fstab

echo "Arch is now installed. Please chroot"
