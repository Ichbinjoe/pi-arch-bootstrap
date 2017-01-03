resources=/bootstrap

cat $resources/pacman.conf >> /etc/pacman.conf

pacman -Syu --noconfirm # shouldn't do much other than update repos
pacman --noconfirm -Sy yaourt

mkinitcpio -p linux
