#!/bin/bash
set -e  # Exit immediately on any error

# 1. Get essential tools via BusyBox
curl -LO https://www.busybox.net/downloads/binaries/1.35.0-x86_64-linux-musl/busybox
chmod +x busybox
ln -s busybox cmp
ln -s busybox diff
export PATH="$PATH:$(pwd)"  # Add to PATH

# 2. Build libmicrohttpd
curl -L https://ftp.gnu.org/gnu/libmicrohttpd/libmicrohttpd-0.9.77.tar.gz -o libmicrohttpd.tar.gz
tar -xzf libmicrohttpd.tar.gz
cd libmicrohttpd-0.9.77 || exit

# Disable features requiring extra dependencies
./configure --prefix="$PWD/../libmicrohttpd" \
  --enable-static \
  --disable-https \
  --disable-doc

make && make install
cd ..

# 3. Compile with explicit pthread linking
gcc -o tieba tieba.c \
  -I./libmicrohttpd/include \
  -L./libmicrohttpd/lib \
  -lmicrohttpd \
  -lpthread  # Essential for Linux threading