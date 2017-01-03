resources=/bootstrap

cat $resources/pacman.conf >> /etc/pacman.conf

useradd -r -s /usr/bin/sh docker-user
useradd -G wheel joe
passwd -d joe
mkdir -p /home/joe/.ssh
wget -O /home/joe/.ssh/authorized_keys https://github.com/ichbinjoe.keys

pacman -Syu --noconfirm # shouldn't do much other than update repos
pacman --noconfirm -Sy yaourt

modprobe fuse

systemctl enable sshd
systemctl enable docker
systemctl enable glusterd

mkinitcpio -p linux
