#!/bin/sh

# esp8266
TOOLCHAIN_VER=esp2020r3
TOOLCHAIN=xtensa-lx106-elf-gcc8_4_0-$TOOLCHAIN_VER
DOWNLOADLINK=https://dl.espressif.com/dl/$TOOLCHAIN
[ ! -f $TOOLCHAIN-macos.tar.gz   ]     && curl -L $DOWNLOADLINK-macos.tar.gz       --output $TOOLCHAIN-macos.tar.gz
[ ! -f $TOOLCHAIN-linux-i686.tar.gz ]  && curl -L $DOWNLOADLINK-linux-i686.tar.gz  --output $TOOLCHAIN-linux-i686.tar.gz
[ ! -f $TOOLCHAIN-linux-amd64.tar.gz ] && curl -L $DOWNLOADLINK-linux-amd64.tar.gz --output $TOOLCHAIN-linux-amd64.tar.gz

# esp32
TOOLCHAIN_VER=esp-2021r2
TOOLCHAIN=xtensa-esp32-elf-gcc8_4_0-$TOOLCHAIN_VER
DOWNLOADLINK=https://github.com/espressif/crosstool-NG/releases/download/$TOOLCHAIN_VER/$TOOLCHAIN
[ ! -f $TOOLCHAIN-macos.tar.gz  ]        && curl -L $DOWNLOADLINK-macos.tar.gz       --output $TOOLCHAIN-macos.tar.gz
[ ! -f $TOOLCHAIN-linux-i686.tar.gz ]    && curl -L $DOWNLOADLINK-linux-i686.tar.gz  --output $TOOLCHAIN_VER-linux-i686.tar.gz
[ ! -f $TOOLCHAIN-linux-amd64.tar.gz ]   && curl -L $DOWNLOADLINK-linux-amd64.tar.gz --output $TOOLCHAIN_VER-linux-amd64.tar.gz

