#!/bin/bash

function run {
    root=$1
    mkdir -p $root

    mkdir -p $root/etc # early strap of mkinitcpio so initial doesn't fail
    
    cp ./mkinitcpio.conf "$root/etc/mkinitcpio.conf"

    cp ./sudoers "$root/etc/sudoers"
    chmod 644 "$root/etc/sudoers"

    mkdir -p "$root/etc/ssh"    
    cp ./sshd_config "$root/etc/ssh/sshd_config"
    chmod 444 "$root/etc/ssh/sshd_config"

    cp ./bootstrap.sh "$root/bootstrap.sh"
    mkdir -p "$root/bootstrap"
    cp -r ./bootstrap-resources/* "$root/bootstrap"

    mkdir -p "$root/usr/lib/initcpio/install"
    mkdir -p "$root/usr/lib/initcpio/hooks"

    cp ./mountr/install "$root/usr/lib/initcpio/install/mountr"
    cp ./mountr/hook "$root/usr/lib/initcpio/hooks/mountr"
    cp ./auto-mount/install "$root/usr/lib/initcpio/install/auto-mount"
    cp ./auto-mount/hook "$root/usr/lib/initcpio/hooks/auto-mount"
    
    pacstrap -d "$root" base base-devel btrfs-progs sudo wget curl docker docker-compose docker-machine mkinitcpio-nfs-utils glusterfs nfs-utils parted bind-tools

    cat ./flash-udev.rules >> /usr/lib/udev/rules.d/60-persistent-storage.rules

    arch-chroot "$root" sh /bootstrap.sh
   
    mkdir -p "$root/os"
    mkdir -p "$root/persistent"

    rm "$root/bootstrap.sh"
    rm -r "$root/bootstrap"
}

function help {
    cat <<HELPEOF
This script consumes one (1) parameter:

1) The directory where all other paired scripts dump their artifacts.

This script in particular take a variety of artifacts, depending on the
artifact folder (\$ARTIFACTS):

\$ARTIFACTS/arch/vmlinuz-linux - The kernel for all devices which PXE boot
    against this server
\$ARTIFACTS/arch/initrd - The initial ram disk for servers which PXE boot
    off of this server to load
\$ARTIFACTS/arch/filesystem.squashfs - The root image for servers which boot from
    this PXE boot server

The script takes the artifacts, chews them up, and spits them into the SD
card along with a full installation of ArchLinux, tftpd, and sshd.

Since this script is invoked on a seperate architecture system, we can't
chroot into our installation. To counteract this and make our lives easier,
this script also installs a nice bootstrap script which is run on each 
boot of the server. If it is the first time the filesystem is bootstrapped,
the script runs, installing software/doing any architecture specific
operations.
HELPEOF
}

if [ "$1" == "help" ]; then
    help
    exit 0
fi

if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters: $0 [resource directory]"
    help
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run by root!"
    exit 1
fi

set -e

run $1 $2
