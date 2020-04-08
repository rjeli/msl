#!/bin/bash
set -euo pipefail

APP_DIR=$HOME/.local/share/msl
mkdir -p $APP_DIR

XHYVE_ARGS=""
add_arg() {
    XHYVE_ARGS="$XHYVE_ARGS $*"
}
KERNEL=$APP_DIR/vmlinuz-whatever
INITRD=$APP_DIR/initrd-whatever
CMDLINE="earlyprintk=serial console=ttyS0 root=/dev/vda1 ro"

dl_cached() {
    url=$1
    cached_path=$APP_DIR/$(basename $url)
    if [ -f $cached_path ]; then
        echo >&2 using cached $cached_path
    else
        echo >&2 downloading $url
        curl -L $url >$cached_path
    fi
    echo $cached_path
}

start() {
    add_arg -A # acpi
    add_arg -m 4G # ram
    add_arg -s 0:0,hostbridge # pci hostbridge
    add_arg -s 31,lpc -l com1,autopty # pci-isa bridge and isa serial port
    add_arg -s 2:0,virtio-net # network controller
    add_arg -s 3:0,virtio-blk,$APP_DIR/hdd.img # root drive
    echo sudoing to enable networking
    sudo true
    sudo nohup xhyve $XHYVE_ARGS -f kexec,$KERNEL,$INITRD,"$CMDLINE" \
        >$APP_DIR/stdout.log 2>$APP_DIR/stderr.log &
    pid=$!
    echo pid is $pid
    echo $pid >$APP_DIR/pid
    sleep 0.5
    tty=$(egrep -o '/dev/ttys\d+' $APP_DIR/stderr.log)
    echo "linking $APP_DIR/tty -> $tty"
    sudo chmod a+rwx $tty
    ln -s $tty $APP_DIR/tty
}

stop() {
    echo stopping
    [ -f $APP_DIR/pid ] && sudo kill -9 $(cat $APP_DIR/pid)
    echo removing tty symlink
    [ -f $APP_DIR/tty ] && rm $APP_DIR/tty
}

install_msl() {
    buster_url=http://deb.debian.org/debian/dists/buster
    netboot_url=$buster_url/main/installer-amd64/current/images/netboot
    iso_path=$(dl_cached $netboot_url/mini.iso)
    KERNEL=$(dl_cached $netboot_url/debian-installer/amd64/linux)
    INITRD=$(dl_cached $netboot_url/debian-installer/amd64/initrd.gz)
    echo creating 8gb hdd
    dd if=/dev/zero of=$APP_DIR/hdd.img bs=1g count=8
    echo starting installer
    add_arg -s 4:0,ahci-cd,$iso_path
    start
    echo attaching to serial for configuration
    screen $APP_DIR/tty
}

if [ $# -lt 1 ]; then
    echo must provide command
    exit 1
fi

case $1 in
    install)
        install_msl
        ;;
    start)
        start
        ;;
    stop)
        stop
        ;;
    *)
        echo unrecognized command $1
        exit 1
        ;;
esac
