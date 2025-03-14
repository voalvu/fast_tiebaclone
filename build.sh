#!/bin/bash

# Download and build libmicrohttpd
wget https://ftp.gnu.org/gnu/libmicrohttpd/libmicrohttpd-latest.tar.gz
tar -xzf libmicrohttpd-latest.tar.gz
cd libmicrohttpd-* || exit
./configure --prefix="$PWD/../libmicrohttpd" --enable-static
make && make install
cd ..

# Compile your C code
gcc -o tieba tieba.c \
  -I./libmicrohttpd/include \
  -L./libmicrohttpd/lib \
  -lmicrohttpd -lws2_32