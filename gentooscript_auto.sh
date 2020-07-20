#!/bin/bash

set -2

echo "root:123456" | chpasswd

useradd -m -G users shail
echo "shail:123456" | chpasswd

rc-service sshd start

ping -c 3 www.gnu.org

parted -a optimal /dev/sda < parted.txt

mkfs.ext2 /dev/sda2
mkfs.ext4 /dev/sda4

mkswap /dev/sda3
swapon /dev/sda3

mount /dev/sda4 /mnt/gentoo

cd /mnt/gentoo

wget https://bouncer.gentoo.org/fetch/root/all/releases/amd64/autobuilds/20200715T214503Z/stage3-amd64-20200715T214503Z.tar.xz

tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner

mkdir --parents /etc/portage/repos.conf

cp /usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev

chroot /mnt/gentoo /bin/bash
source /etc/profile
export PS1="(chroot) ${PS1}"

mount /dev/sda2 /boot

emerge-webrsync

emerge --sync

emerge --verbose --update --deep --newuse @world

ls /usr/share/zoneinfo

echo "Asia/Kolkata" > /etc/timezone

emerge --config sys-libs/timezone-data

locale-gen

env-update && source /etc/profile && export PS1="(chroot) ${PS1}"

emerge sys-kernel/gentoo-sources

ls -l /usr/src/linux

emerge sys-apps/pciutils

cd /usr/src/linux

make menuconfig

make && make modules_install

make install

mkdir -p /etc/modules-load.d

emerge --noreplace net-misc/netifrc

echo "config_eth0="dhcp"" >> /etc/conf.d/net

cd /etc/init.d
ln -s net.lo net.eth0
rc-update add net.eth0 default

emerge sys-process/cronie

rc-update add cronie default

crontab /etc/crontab

rc-update add sshd default

emerge net-misc/dhcpcd

echo 'GRUB_PLATFORMS="efi-64"' >> /etc/portage/make.conf

emerge sys-boot/grub:2

emerge --update --newuse --verbose sys-boot/grub:2

grub-install --target=x86_64-efi --efi-directory=/boot

grub-mkconfig -o /boot/grub/grub.cfg

reboot
