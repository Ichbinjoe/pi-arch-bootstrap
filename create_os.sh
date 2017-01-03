#!/bin/sh

temp=$1

truncate -s 1G "$temp/bootstrap.iso"
mkfs.btrfs "$temp/bootstrap.iso"
root=$1/bootstrapfs
mkdir -p "$root"
mount -o loop,discard,compress=lzo "$1/bootstrap.iso" "$root"

pacstrap -d "$root" base intel-ucode
genfstab -U "$root" >> "$root/etc/fstab"

cp ./arch_chroot_bootstrap.sh "$root/bootstrap.sh"
arch-chroot "$root" "sh /bootstrap.sh"
rm "$root/bootstrap.sh"
