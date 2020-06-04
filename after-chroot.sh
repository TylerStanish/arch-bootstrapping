#!/bin/bash
function print_error_message() {
  echo 'failed...'
}

trap 'print_error_message' ERR
read -p "Enter timezone (Central, Eastern, etc):" timezone
read -p "Enter hostname:" hostname


ln -sf /usr/share/zoneinfo/US/$timezone
hwclock --systohc

sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
echo "$hostname" > /etc/hostname
echo "
127.0.0.1 localhost
::1   localhost
127.0.1.1 $hostname.localdomain  $hostname
" > /etc/hosts

passwd
grub-install --target=x86_64-efi --efi-directory=/efi
grub-mkconfig -o /efi/grub/grub.cfg
