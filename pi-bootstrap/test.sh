#!/bin/sh
mkdir -p /tmp/bootstrap
sudo umount /dev/mmcblk0p1
sudo umount /dev/mmcblk0p2
sudo ./create.sh /dev/mmcblk0 /tmp/bootstrap /home/joe/spinrite.iso
echo -e "\a"
