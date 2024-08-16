#!/usr/bin/env bash

## A script for creating Ubuntu bootstraps for Wine compilation.
##
## debootstrap and perl are required
## root rights are required
##
## About 5.5 GB of free space is required
## And additional 2.5 GB is required for Wine compilation

if [ "$EUID" != 0 ]; then
	echo "This script requires root rights!"
	exit 1
fi

if ! command -v debootstrap 1>/dev/null || ! command -v perl 1>/dev/null; then
	echo "Please install debootstrap and perl and run the script again"
	exit 1
fi

# Keep in mind that although you can choose any version of Ubuntu/Debian
# here, but this script has only been tested with Ubuntu 20.04 Focal
export CHROOT_DISTRO="noble"
export CHROOT_MIRROR="https://ftp.uni-stuttgart.de/ubuntu/"

# Set your preferred path for storing chroots
# Also don't forget to change the path to the chroots in the build_wine.sh
# script, if you are going to use it
export MAINDIR=/opt/chroots
export CHROOT="${MAINDIR}"/${CHROOT_DISTRO}_chroot

prepare_chroot () {
	CHROOT_PATH="${CHROOT}"

	echo "Unmount chroot directories. Just in case."
	umount -Rl "${CHROOT_PATH}"

	echo "Mount directories for chroot"
	mount --bind "${CHROOT_PATH}" "${CHROOT_PATH}"
	mount -t proc /proc "${CHROOT_PATH}"/proc
	mount --bind /sys "${CHROOT_PATH}"/sys
	mount --make-rslave "${CHROOT_PATH}"/sys
	mount --bind /dev "${CHROOT_PATH}"/dev
	mount --bind /dev/pts "${CHROOT_PATH}"/dev/pts
	mount --bind /dev/shm "${CHROOT_PATH}"/dev/shm
	mount --make-rslave "${CHROOT_PATH}"/dev

	rm -f "${CHROOT_PATH}"/etc/resolv.conf
	cp /etc/resolv.conf "${CHROOT_PATH}"/etc/resolv.conf

	echo "Chrooting into ${CHROOT_PATH}"
	chroot "${CHROOT_PATH}" /usr/bin/env LC_ALL=en_US.UTF_8 LANGUAGE=en_US.UTF_8 LANG=en_US.UTF-8 \
			TERM=xterm PATH="/bin:/sbin:/usr/bin:/usr/local/bin:/usr/sbin" \
			/opt/prepare_chroot.sh

	echo "Unmount chroot directories"
	umount -l "${CHROOT_PATH}"
	umount "${CHROOT_PATH}"/proc
	umount "${CHROOT_PATH}"/sys
	umount "${CHROOT_PATH}"/dev/pts
	umount "${CHROOT_PATH}"/dev/shm
	umount "${CHROOT_PATH}"/dev
}

create_build_scripts () {
	sdl2_version="2.30.2"
	faudio_version="24.05"
	vulkan_headers_version="1.3.239"
	vulkan_loader_version="1.3.239"
	spirv_headers_version="sdk-1.3.239.0"
 	libpcap_version="1.10.4"

	cat <<EOF > "${MAINDIR}"/prepare_chroot.sh
#!/bin/bash

apt-get update
apt-get -y install nano
apt-get -y install locales
echo en_US.UTF_8 UTF-8 >> /etc/locale.gen
locale-gen

echo deb '${CHROOT_MIRROR}' ${CHROOT_DISTRO} main restricted > /etc/apt/sources.list
echo deb '${CHROOT_MIRROR}' ${CHROOT_DISTRO}-updates main restricted >> /etc/apt/sources.list
echo deb '${CHROOT_MIRROR}' ${CHROOT_DISTRO} universe >> /etc/apt/sources.list
echo deb '${CHROOT_MIRROR}' ${CHROOT_DISTRO}-updates universe >> /etc/apt/sources.list
echo deb '${CHROOT_MIRROR}' ${CHROOT_DISTRO} multiverse >> /etc/apt/sources.list
echo deb '${CHROOT_MIRROR}' ${CHROOT_DISTRO}-updates multiverse >> /etc/apt/sources.list
echo deb '${CHROOT_MIRROR}' ${CHROOT_DISTRO}-backports main restricted universe multiverse >> /etc/apt/sources.list
echo deb http://security.ubuntu.com/ubuntu ${CHROOT_DISTRO}-security main restricted >> /etc/apt/sources.list
echo deb http://security.ubuntu.com/ubuntu ${CHROOT_DISTRO}-security universe >> /etc/apt/sources.list
echo deb http://security.ubuntu.com/ubuntu ${CHROOT_DISTRO}-security multiverse >> /etc/apt/sources.list

echo deb-src '${CHROOT_MIRROR}' ${CHROOT_DISTRO} main restricted >> /etc/apt/sources.list
echo deb-src '${CHROOT_MIRROR}' ${CHROOT_DISTRO}-updates main restricted >> /etc/apt/sources.list
echo deb-src '${CHROOT_MIRROR}' ${CHROOT_DISTRO} universe >> /etc/apt/sources.list
echo deb-src '${CHROOT_MIRROR}' ${CHROOT_DISTRO}-updates universe >> /etc/apt/sources.list
echo deb-src '${CHROOT_MIRROR}' ${CHROOT_DISTRO} multiverse >> /etc/apt/sources.list
echo deb-src '${CHROOT_MIRROR}' ${CHROOT_DISTRO}-updates multiverse >> /etc/apt/sources.list
echo deb-src '${CHROOT_MIRROR}' ${CHROOT_DISTRO}-backports main restricted universe multiverse >> /etc/apt/sources.list
echo deb-src http://security.ubuntu.com/ubuntu ${CHROOT_DISTRO}-security main restricted >> /etc/apt/sources.list
echo deb-src http://security.ubuntu.com/ubuntu ${CHROOT_DISTRO}-security universe >> /etc/apt/sources.list
echo deb-src http://security.ubuntu.com/ubuntu ${CHROOT_DISTRO}-security multiverse >> /etc/apt/sources.list

apt-get update
apt-get -y upgrade
apt-get -y dist-upgrade
apt-get -y install software-properties-common
apt-get update
apt-get -y build-dep wine-development libsdl2 libvulkan1
apt-get -y install cmake flex bison ccache gcc-14 g++-14 wget git gcc-mingw-w64 g++-mingw-w64
apt-get -y install libxpresent-dev libjxr-dev libusb-1.0-0-dev libgcrypt20-dev libpulse-dev libudev-dev libsane-dev libv4l-dev libkrb5-dev libgphoto2-dev liblcms2-dev libcapi20-dev
apt-get -y install libjpeg62-dev samba-dev libfreetype-dev libunwind-dev ocl-icd-opencl-dev libgnutls28-dev libx11-dev libxcomposite-dev libxcursor-dev libxfixes-dev libxi-dev libxrandr-dev 
apt-get -y install libxrender-dev libxext-dev libpcsclite-dev libcups2-dev libosmesa6-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
apt-get -y install python3-pip libxcb-xkb-dev libfontconfig-dev libgl-dev
apt-get -y install meson ninja-build libxml2 libxml2-dev libxkbcommon-dev libxkbcommon0 xkb-data
apt-get -y purge libvulkan-dev libvulkan1 libsdl2-dev libsdl2-2.0-0 libpcap0.8-dev libpcap0.8 --purge --autoremove
apt-get -y purge *gstreamer* --purge --autoremove
apt-get -y build-dep gstreamer1.0 gstreamer1.0-plugins-bad gstreamer1.0-alsa gstreamer1.0-gl
apt-get -y install libdrm-dev
apt-get install -y libclang-18-dev libclang-common-18-dev libclang-cpp18-dev \
  libclc-18 libclc-18-dev libllvmspirvlib-18-dev llvm-18 llvm-18-dev llvm-18-linker-tools \
  llvm-18-runtime llvm-18-tools llvm-spirv-18 libpolly-18-dev llvm-18* clang

export PATH="/usr/local/bin:/bin:/sbin:/usr/bin:/usr/sbin"
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-14 90 --slave /usr/bin/g++ g++ /usr/bin/g++-14 --slave /usr/bin/gcov gcov /usr/bin/gcov-14

# Installing llvm-mingw...
if ! [ -d /usr/local/llvm-mingw ]; then
	wget -O llvm-mingw.tar.xz https://github.com/mstorsjo/llvm-mingw/releases/download/20240619/llvm-mingw-20240619-ucrt-ubuntu-20.04-x86_64.tar.xz
	tar -xf llvm-mingw.tar.xz -C /usr/local
	mv /usr/local/llvm-mingw-20240619-ucrt-ubuntu-20.04-x86_64 /usr/local/llvm-mingw
	rm llvm-mingw.tar.xz
fi

wget -O /usr/include/linux/userfaultfd.h https://raw.githubusercontent.com/zen-kernel/zen-kernel/f787614c40519eb2c8ebdc116b2cd09d46e5ec85/include/uapi/linux/userfaultfd.h

mkdir /opt/build_libs
cd /opt/build_libs
wget -O sdl.tar.gz https://www.libsdl.org/release/SDL2-${sdl2_version}.tar.gz
wget -O faudio.tar.gz https://github.com/FNA-XNA/FAudio/archive/${faudio_version}.tar.gz
wget -O vulkan-loader.tar.gz https://github.com/KhronosGroup/Vulkan-Loader/archive/v${vulkan_loader_version}.tar.gz
wget -O vulkan-headers.tar.gz https://github.com/KhronosGroup/Vulkan-Headers/archive/v${vulkan_headers_version}.tar.gz
wget -O spirv-headers.tar.gz https://github.com/KhronosGroup/SPIRV-Headers/archive/refs/tags/vulkan-sdk-1.3.283.0.tar.gz
wget -O libpcap.tar.gz https://www.tcpdump.org/release/libpcap-${libpcap_version}.tar.gz
if [ -d /usr/lib/x86_64-linux-gnu ]; then wget -O wine.deb https://dl.winehq.org/wine-builds/ubuntu/dists/jammy/main/binary-amd64/wine-stable_9.0.0.0~jammy-1_amd64.deb; fi
git clone https://gitlab.winehq.org/wine/vkd3d.git --depth 1
git clone https://gitlab.freedesktop.org/gstreamer/gstreamer.git -b 1.24 --depth 1
#
tar xf sdl.tar.gz
tar xf faudio.tar.gz
tar xf vulkan-loader.tar.gz
tar xf vulkan-headers.tar.gz
tar xf spirv-headers.tar.gz
tar xf libpcap.tar.gz
export CFLAGS="-O2"
export CXXFLAGS="-O2"
mkdir build && cd build
cmake ../SDL2-${sdl2_version} && make -j$(nproc) && make install
cd ../ && rm -r build && mkdir build && cd build
cmake ../FAudio-${faudio_version} && make -j$(nproc) && make install
cd ../ && rm -r build && mkdir build && cd build
cmake ../Vulkan-Headers-${vulkan_headers_version} && make -j$(nproc) && make install
cd ../ && rm -r build && mkdir build && cd build
cmake ../Vulkan-Loader-${vulkan_loader_version}
make -j$(nproc)
make install
cd ../ && rm -r build && mkdir build && cd build
cmake ../SPIRV-Headers-vulkan-sdk-1.3.283.0 && make -j$(nproc) && make install
cd ../ && dpkg -x wine.deb .
cp opt/wine-stable/bin/widl /usr/bin
cd /opt/build_libs
cd vkd3d && ./autogen.sh
cd ../ && rm -r build && mkdir build && cd build
../vkd3d/configure && make -j$(nproc) && make install
cd ../ && rm -r build && mkdir build && cd build
../libpcap-${libpcap_version}/configure && make -j$(nproc) install
cd ../gstreamer
meson setup build
ninja -C build
ninja -C build install
cd /opt && rm -r /opt/build_libs

# Cleaning...
apt-get -y clean
apt-get -y autoclean
EOF

	chmod +x "${MAINDIR}"/prepare_chroot.sh
	mv "${MAINDIR}"/prepare_chroot.sh "${CHROOT}"/opt
}

mkdir -p "${MAINDIR}"

if [ -z "$DEBOOTSTRAP_DIR" ]; then
	if [ -x /debootstrap/debootstrap ]; then
		DEBOOTSTRAP_DIR=/debootstrap
	else
		DEBOOTSTRAP_DIR=/usr/share/debootstrap
	fi
fi

echo -n "amd64" > "${DEBOOTSTRAP_DIR}"/arch
debootstrap --arch=amd64 $CHROOT_DISTRO "${CHROOT}" $CHROOT_MIRROR

create_build_scripts
prepare_chroot

rm "${CHROOT}"/opt/prepare_chroot.sh
echo "Done"
