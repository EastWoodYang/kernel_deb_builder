#!/usr/bin/env bash

VERSION=$(grep 'Kernel Configuration' < config | awk '{print $3}')

# add deb-src to sources.list
sed -i "/deb-src/s/# //g" /etc/apt/sources.list

# install dep
apt update
apt install -y git wget xz-utils make gcc flex bison dpkg-dev bc rsync kmod cpio libssl-dev debhelper libelf-dev u-boot-tools gcc-aarch64-linux-gnu
apt build-dep -y linux

export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=arm64

# change dir to workplace
cd "${GITHUB_WORKSPACE}" || exit

# download kernel source

git clone -q --single-branch --depth=1 --branch=main https://github.com/unifreq/linux-6.6.y
cd linux-6.6.y
# wget https://github.com/unifreq/linux-6.6.y/archive/refs/tags/linux-6.6.31.tar.gz
# tar -xf linux-6.6.31.tar.gz
# cd linux-6.6.y-linux-6.6.31 || exit

# copy config file
cp ../config .config

# disable DEBUG_INFO to speedup build
scripts/config --disable DEBUG_INFO

# apply patches
# shellcheck source=src/util.sh
source ../patch.d/*.sh

# build deb packages
# CPU_CORES=$(($(grep -c processor < /proc/cpuinfo)*2))
# make ARCH=arm64 deb-pkg -j"$CPU_CORES"

make ARCH=arm64 .config

nice make -j`nproc` bindeb-pkg
# nice make ARCH=arm64 CROSS_COMPLE=gcc-aarch64-linux-gnu bindeb-pkg



# move deb packages to artifact dir
cd ..
rm -rfv *dbg*.deb
mkdir "artifact"
mv ./*.deb artifact/
