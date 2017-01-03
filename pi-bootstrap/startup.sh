#!/bin/sh

if [ -f /etc/bootstrapped ]; then
    echo "Already bootstrapped..."
    exit 0
fi

set -e

useradd -G wheel joe
mkdir -p /home/joe/.ssh

chown -R joe:joe /srv/tftp
chmod -R 555 /srv/tftp

pacman -Syyu --noconfirm
pacman -S --noconfirm tftp-hpa sudo wget curl nfs-utils
wget -O /home/joe/.ssh/authorized_keys https://github.com/ichbinjoe.keys
systemctl enable tftpd.service
systemctl enable sshd.service
systemctl enable nfs-server.service
# will be cleaned up by reboot at end
touch /etc/bootstrapped
shutdown -r now
