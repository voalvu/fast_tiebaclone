#!/bin/bash

set -e  # Exit on any error

# Download and build libmicrohttpd using curl

curl -LO https://ftp.gnu.org/gnu/libmicrohttpd/libmicrohttpd-latest.tar.gz

tar -xzf libmicrohttpd-latest.tar.gz

cd "$(ls -d libmicrohttpd-*/ | head -n 1)"

./configure --prefix="$PWD/../libmicrohttpd" --enable-static

make && make install

cd ..

# Compile the C code

gcc -o tieba tieba.c -I./libmicrohttpd/include -L./libmicrohttpd/lib -lmicrohttpd -lws2_32