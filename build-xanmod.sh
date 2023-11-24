#!/bin/bash

PACKAGE="linux-xanmod"
MAKEPKG_PATH="/home/builduser/.config/pacman"
XANMOD_CONFIG_PATH="/home/builduser/.config/linux-xanmod"
GPG_KEYS=('ABAF11C65A2970B130ABE3C479BE3E4300411886'
          '647F28654894E3BD457199BE38DBBDC86092693E')

pacman-key --init
pacman-key --populate
pacman -Syu --noconfirm
pacman -S --noconfirm --needed wget git

rm -rf /var/cache/pacman/pkg/*

useradd -m -s /bin/bash builduser
chown builduser:builduser -R /build
passwd -d builduser
printf 'builduser ALL=(ALL) ALL\n' | tee -a /etc/sudoers
git config --global --add safe.directory /build

cd /build

sudo -u builduser bash -c "mkdir -p $MAKEPKG_PATH && mv /build/makepkg.conf $MAKEPKG_PATH && chown builduser:builduser -R $MAKEPKG_PATH"

sudo -u builduser bash -c "mkdir -p $XANMOD_CONFIG_PATH && mv /build/linux-xanmod-config $XANMOD_CONFIG_PATH/myconfig && chown builduser:builduser -R $XANMOD_CONFIG_PATH"

git clone https://aur.archlinux.org/linux-xanmod.git

chown builduser:builduser -R $PACKAGE && cd $PACKAGE

for GPG_KEY in ${GPG_KEYS[@]}
do
    sudo -u builduser bash -c "gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys $GPG_KEY"
done

sudo -u builduser bash -c "env HOME=/home/builduser _microarchitecture=93 use_numa=n use_tracers=y _config=config_x86-64-v3 _compress_modules=y makepkg -sc --noconfirm"

find ./ -name "*.pkg.tar.*" -exec mv {} /build/ \;

cd /build

wget --quiet https://github.com/Bryan2333/build-xanmod-for-arch/releases/download/packages/xanmod.db.tar.xz

repo-add -n xanmod.db.tar.xz *.pkg.tar.*
