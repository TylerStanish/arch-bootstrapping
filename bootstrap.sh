#!/bin/bash
function print_error_message() {
  echo 'failed...'
}
trap 'print_error_message' ERR

read -p "Enter block device to install onto: " location
read -p "Enter block device partition prefix (e.g. /dev/nvme0n1p where partitions are like /dev/nvme0n1p1):" partition_prefix
read -p "Enter swap space in gigabytes" swap_size
read -p "Enter root password" root_password
read -p "Enter hostname" hostname

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
" | fdisk $location

mkfs.fat ${partition_prefix}1
mkfs.ext4 ${partition_prefix}2
mkswap ${partition_prefix}3
swapon ${partition_prefix}3

mount ${partition_prefix}2 /mnt
mkdir /mnt/efi
mount ${partition_prefix}1 /mnt/efi


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
  dialog netctl grub efibootmgr wpa_supplicant

genfstab -U /mnt >> /mnt/etc/fstab

echo "Arch is now installed. chroot'ing now"
echo "
ln -sf /usr/share/zoneinfo/US/Central
hwclock --systohc
sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
echo '$hostname' > /etc/hostname
echo '
127.0.0.1 localhost
::1   localhost
127.0.1.1 $hostname.localdomain  $hostname
' > /etc/hosts

echo '$root_password' | passwd '$root_password' --stdin
grub-install --target=x86_64-efi --efi-directory=/efi
grub-mkconfig -o /boot/grub/grub.cfg
# grub-mkconfig -o /efi/grub.cfg
" | arch-chroot /mnt
