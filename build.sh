#!/bin/bash
set -e

# Check if pre-built vendor exists
if [ ! -d "vendor" ]; then
  echo "Building dependencies from scratch..."
  
  # 1. Install essential tools
  curl -LO https://www.busybox.net/downloads/binaries/1.35.0-x86_64-linux-musl/busybox
  chmod +x busybox
  ln -sf busybox cmp
  ln -sf busybox diff
  export PATH="$PATH:$(pwd)"

  # 2. Build libmicrohttpd
  curl -L https://ftp.gnu.org/gnu/libmicrohttpd/libmicrohttpd-0.9.77.tar.gz -o libmicrohttpd.tar.gz
  tar -xzf libmicrohttpd.tar.gz
  cd libmicrohttpd-0.9.77
  ./configure --prefix="$PWD/../vendor" \
    --enable-static \
    --disable-https \
    --disable-doc
  make && make install
  cd ..
  
  # 3. Auto-commit (ONLY FIRST RUN)
  if [ ! -f ".vendor_committed" ] && [ -n "$GIT_TOKEN" ]; then
    git config --global user.name "Vercel Builder"
    git config --global user.email "builder@vercel.com"
    git add vendor/
    git commit -m "[CI] Add pre-built dependencies"
    git push "https://${GIT_TOKEN}@github.com/voalvu/fast_tiebaclone.git" main
    touch .vendor_committed
  fi
fi

# Always build main binary
mkdir -p public
gcc -o public/tieba tieba.c \
  -I./vendor/include \
  -L./vendor/lib \
  -lmicrohttpd \
  -lpthread