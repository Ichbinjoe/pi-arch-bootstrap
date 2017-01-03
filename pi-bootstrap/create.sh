#!/bin/bash

function run {
    device=$1
    artifacts=$2
    spinrite=$3

    echo "Parted: create partition table"
    parted -s -a optimal $device mklabel msdos mkpart primary fat32 '0%' 100MiB mkpart primary 100MiB '100%'

    echo "Make /boot FAT fs"
    mkfs.vfat ${device}p1
    BOOT=$artifacts/pi-bootstrap/boot-temp
    mkdir -p $BOOT
    mount $1p1 $BOOT

    echo "Make / ext4 fs"
    mkfs.ext4 -F $1p2
    ROOT=$artifacts/pi-bootstrap/root-temp
    mkdir -p $ROOT
    mount $1p2 $ROOT

    echo "Getting ArchLinxArm"
    wget --tries=0 --read-timeout=5 -O $artifacts/pi-bootstrap/arch-pi.tar.gz http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-2-latest.tar.gz

    echo "Unzipping root fs"
    bsdtar -xpf $artifacts/pi-bootstrap/arch-pi.tar.gz -C $ROOT
    sync

    echo "Copying over boot"
    mv $ROOT/boot/* $BOOT
    
    echo "Setting up tftpd/bootstrap/sshd"
    cp ./confd-tftpd $ROOT/etc/conf.d/tftpd

    cp ./fstab $ROOT/etc/fstab

    tftp="$ROOT/srv/tftp"
    mkdir -p $tftp

    nfs="$ROOT/srv/nfs"
    mkdir -p $nfs

    cp ./exports $ROOT/etc/exports

    echo "Retrieving and installing pxelinux.0 6.03"
    wget --tries=0 --read-timeout=5 -O "$artifacts/pi-bootstrap/syslinux.tar.gz" "https://www.kernel.org/pub/linux/utils/boot/syslinux/syslinux-6.03.tar.gz"

    syslinux="$artifacts/pi-bootstrap/syslinux"
    mkdir -p "$syslinux"
    tar -zxf "$artifacts/pi-bootstrap/syslinux.tar.gz" -C "$syslinux/"
    
    syslinux="$syslinux/syslinux-6.03" 

    cp "$syslinux/bios/core/pxelinux.0" "$tftp/pxelinux.0"
    cp "$syslinux/bios/com32/elflink/ldlinux/ldlinux.c32" "$tftp/ldlinux.c32"
    cp "$syslinux/bios/com32/libutil/libutil.c32" "$tftp/libutil.c32"
    cp "$syslinux/bios/com32/menu/menu.c32" "$tftp/menu.c32"
    cp "$syslinux/efi32/efi/syslinux.efi" "$tftp/syslinux32.efi"
    cp "$syslinux/efi64/efi/syslinux.efi" "$tftp/syslinux64.efi"
    cp "$syslinux/bios/memdisk/memdisk" "$tftp/memdisk"

    mkdir "$tftp/pxelinux.cfg"
    cp "./common" "$tftp/pxelinux.cfg/common"
    if [ $# -gt 2 ]; then
        cat ./spinrite >> "$tftp/pxelinux.cfg/common"
        cp $3 "$tftp/spinrite.iso"
    fi
    cp "./server-boot" "$tftp/pxelinux.cfg/server-boot"
    cp "./graphics.conf" "$tftp/pxelinux.cfg/graphics.conf"
    cp "./client-boot" "$tftp/pxelinux.cfg/default"
    cat ./server-list | while read i; do
        if [[ $i != \#* ]]; then
           cp "./default-server" "$tftp/pxelinux.cfg/01-$i" 
        fi
    done

    mkdir "$tftp/arch"
    
    mkdir -p "$nfs/arch"
    curr_dir=$(pwd)
    cd ../arch-bootstrap
    ./create.sh "$nfs/arch"
    cd $curr_dir

    mv "$nfs/arch/boot/vmlinuz-linux" "$tftp/arch/vmlinuz-linux"
    mv "$nfs/arch/boot/initramfs-linux.img" "$tftp/arch/initrd"
    rm -r "$nfs/arch/boot"

    cd ../arch-server-bootstrap
    ./create.sh "$nfs/arch-server"
    cd $curr_dir

    mkdir -p "$tftp/arch-server"

    mkdir -p "$nfs/hostname"

    mv "$nfs/arch-server/boot/vmlinuz-linux" "$tftp/arch-server/vmlinuz-linux"
    mv "$nfs/arch-server/boot/initramfs-linux.img" "$tftp/arch-server/initrd"
    rm -r "$nfs/arch-server/boot"

    mkdir "$tftp/memtest"
    wget --tries=0 --read-timeout=5 -O "$artifacts/pi-bootstrap/memtest.gz" "http://www.memtest.org/download/5.01/memtest86+-5.01.bin.gz"
    gunzip -c "$artifacts/pi-bootstrap/memtest.gz" > "$tftp/memtest/memtest"

    mkdir "$tftp/clonezilla"
    wget --tries=0 --read-timeout=5 -O "$artifacts/pi-bootstrap/clonezilla.zip" "https://osdn.net/frs/redir.php?m=pumath&f=%2Fclonezilla%2F66611%2Fclonezilla-live-2.4.9-17-amd64.zip"
    unzip -j "$artifacts/pi-bootstrap/clonezilla.zip" live/vmlinuz live/initrd.img live/filesystem.squashfs -d "$tftp/clonezilla"

    mkdir "$tftp/gparted"
    wget --tries=0 --read-timeout=5 -O "$artifacts/pi-bootstrap/gparted.zip" "http://downloads.sourceforge.net/project/gparted/gparted-live-stable/0.27.0-1/gparted-live-0.27.0-1-i686.zip?r=https%3A%2F%2Fsourceforge.net%2Fprojects%2Fgparted%2Ffiles%2Fgparted-live-stable%2F0.27.0-1%2F&ts=1479786297&use_mirror=kent"
    unzip -j "$artifacts/pi-bootstrap/gparted.zip" live/{vmlinuz,initrd.img,filesystem.squashfs} -d "$tftp/gparted"

    chmod -R 644 $ROOT/srv/tftp

    mkdir -p $ROOT/etc/systemd/system/network-online.target.wants

    ln -s ../../../../usr/lib/systemd/sytsem/systemd-networkd-wait-online.services $ROOT/etc/systemd/system/network-online.target.wants/systemd-networkd-wait-online.service

    cp ./startup.sh $ROOT/usr/bin/startup-bootstrap.sh
    chmod +111 $ROOT/usr/bin/startup-bootstrap.sh
    cp startup-systemd.service $ROOT/usr/lib/systemd/system/startup-systemd.service
    ln -s ../../../usr/lib/systemd/system/startup-systemd.service $ROOT/etc/systemd/system/multi-user.target.wants/startup-systemd.service

    cp ./sudoers $ROOT/etc/sudoers
    chmod 440 $ROOT/etc/sudoers
    chown root:root $ROOT/etc/sudoers

    cp ./sshd_config $ROOT/etc/ssh/sshd_config


    echo "Cleanup"
    umount $ROOT $TEMP
}

function help {
    cat <<HELPEOF
This script consumes two (2) parameters:

1) The SD card block device
2) The directory where all other paired scripts dump their artifacts.
Optional: 3) Location of the spinrite bootable iso

This script in particular take a variety of artifacts, depending on the
artifact folder (\$ARTIFACTS):

\$ARTIFACTS/server/vmlinuz-linux - The kernel for all devices which PXE boot
    against this server
\$ARTIFACTS/server/initrd - The initial ram disk for servers which PXE boot
    off of this server to load
\$ARTIFACTS/server/filesystem.squashfs - The root image for servers which boot from
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

if [ "$#" -lt 2 ]; then
    echo "Illegal number of parameters: $0 [sd card] [resource directory]"
    help
    exit 1
fi

set -e

if [ $# -gt 2 ]; then
    run $1 $2 $3
else
    run $1 $2
fi
