#!/bin/bash

set -e
BUILDDIR=$(pwd)
TMPDIR=$(mktemp -d)
ARCH="amd64"
cd $TMPDIR

set -x

mkdir -m 755 $TMPDIR/dev/
mknod -m 600 $TMPDIR/dev/console c 5 1
mknod -m 600 $TMPDIR/dev/initctl p
mknod -m 666 $TMPDIR/dev/full c 1 7
mknod -m 666 $TMPDIR/dev/null c 1 3
mknod -m 666 $TMPDIR/dev/ptmx c 5 2
mknod -m 666 $TMPDIR/dev/random c 1 8
mknod -m 666 $TMPDIR/dev/tty c 5 0
mknod -m 666 $TMPDIR/dev/tty0 c 4 0
mknod -m 666 $TMPDIR/dev/urandom c 1 0
mknod -m 666 $TMPDIR/dev/zero c 1 5

# Set variables
if [ -d /etc/dnf/vars ] ; then
    mkdir -p -m 755 $TMPDIR/etc/dnf
    cp -ar /etc/dnf/vars $TMPDIR/etc/dnf/vars
fi

dnf -c /etc/dnf/dnf.conf --installroot=$TMPDIR --releasever=/ --setopt=tsflags=nodocs --setopt=group_package_types=mandatory -y groupinstall "Core"
dnf -c /etc/dnf/dnf.conf --installroot=$TMPDIR -y clean all

cat > $TMPDIR/etc/sysconfig/network <<EOF
NETWORKING=yes
HOSTNAME=localhost.localdomain
EOF

# Remove extra locales
rm -rf $TMPDIR/usr/{{lib,share}/locale,{lib,lib64}/gconv,bin/localedef,sbin/build-locale-archive}
# Remove extra docs / man pages
rm -rf $TMPDIR/usr/share/{man,doc,info,gnome/help}
# Remove cracklib
rm -rf $TMPDIR/usr/share/cracklib
# Remove i18n
rm -rf $TMPDIR/usr/share/i18n
# Remove yum / dnf cache
if [ -d $TMPDIR/var/cache/yum ] ; then
    rm -rf $TMPDIR/var/cache/yum
    mkdir -p --mode=0755 $TMPDIR/var/cache/yum
fi
rm -rf $TMPDIR/var/cache/dnf
mkdir -p --mode=0755 $TMPDIR/var/cache/dnf
# Remove sln
rm -rf $TMPDIR/sbin/sln
# Remove ldconfig
rm -rf $TMPDIR/etc/ld.so.cache $TMPDIR/var/cache/ldconfig
mkdir -p --mode=0755 $TMPDIR/var/cache/ldconfig

# Copy our own files
cp $BUILDDIR/linux_files/wsl.conf $TMPDIR/etc/wsl.conf
mkdir $TMPDIR/etc/fonts
cp $BUILDDIR/linux_files/local.conf $TMPDIR/etc/fonts/local.conf

tar --numeric-owner -czvf $BUILDDIR/install.tar.gz *
