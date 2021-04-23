#!/bin/sh
[ ! -f xtensa-lx106-elf-macos-1.22.0-100-ge567ec7-5.2.0.tar.gz   ] && curl -L https://dl.espressif.com/dl/xtensa-lx106-elf-macos-1.22.0-100-ge567ec7-5.2.0.tar.gz   --output xtensa-lx106-elf-macos-1.22.0-100-ge567ec7-5.2.0.tar.gz
[ ! -f xtensa-lx106-elf-linux32-1.22.0-100-ge567ec7-5.2.0.tar.gz ] && curl -L https://dl.espressif.com/dl/xtensa-lx106-elf-linux32-1.22.0-100-ge567ec7-5.2.0.tar.gz --output xtensa-lx106-elf-linux32-1.22.0-100-ge567ec7-5.2.0.tar.gz
[ ! -f xtensa-lx106-elf-linux64-1.22.0-100-ge567ec7-5.2.0.tar.gz ] && curl -L https://dl.espressif.com/dl/xtensa-lx106-elf-linux64-1.22.0-100-ge567ec7-5.2.0.tar.gz --output xtensa-lx106-elf-linux64-1.22.0-100-ge567ec7-5.2.0.tar.gz
[ ! -f xtensa-esp32-elf-gcc8_4_0-esp-2020r3-macos.tar.gz  ]        && curl -L https://dl.espressif.com/dl/xtensa-esp32-elf-gcc8_4_0-esp-2020r3-macos.tar.gz         --output xtensa-esp32-elf-gcc8_4_0-esp-2020r3-macos.tar.gz
[ ! -f xtensa-esp32-elf-gcc8_4_0-esp-2020r3-linux-i686.tar.gz ]    && curl -L https://dl.espressif.com/dl/xtensa-esp32-elf-gcc8_4_0-esp-2020r3-linux-i686.tar.gz    --output xtensa-esp32-elf-gcc8_4_0-esp-2020r3-linux-i686.tar.gz
[ ! -f xtensa-esp32-elf-gcc8_4_0-esp-2020r3-linux-amd64.tar.gz ]   && curl -L https://dl.espressif.com/dl/xtensa-esp32-elf-gcc8_4_0-esp-2020r3-linux-amd64.tar.gz   --output xtensa-esp32-elf-gcc8_4_0-esp-2020r3-linux-amd64.tar.gz
