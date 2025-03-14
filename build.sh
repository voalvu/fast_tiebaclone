#!/bin/bash
set -e

# Check for vendor directory
if [ ! -d "vendor" ]; then
  echo "=== Building dependencies ==="
  
  # 1. Install tools
  curl -LO https://www.busybox.net/downloads/binaries/1.35.0-x86_64-linux-musl/busybox
  chmod +x busybox
  ln -sf busybox cmp
  ln -sf busybox diff
  export PATH="$PATH:$(pwd)"

  # 2. Build libmicrohttpd
  curl -L https://ftp.gnu.org/gnu/libmicrohttpd/libmicrohttpd-0.9.77.tar.gz -o libmicrohttpd.tar.gz
  tar -xzf libmicrohttpd.tar.gz
  cd libmicrohttpd-0.9.77
  ./configure --prefix="$PWD/../vendor" --enable-static --disable-https
  make && make install
  cd ..

  # 3. Conditional git push
  if [ -n "$GIT_TOKEN" ] && [ ! -f ".vendor_committed" ]; then
    echo "=== Attempting git commit ==="
    
    # Configure git
    git config --global user.name "Vercel Bot"
    git config --global user.email "bot@vercel.com"
    
    # Check branch existence
    if ! git rev-parse --verify main >/dev/null 2>&1; then
      git checkout -b main
    fi
    
    # Commit and push
    git add vendor
    git commit -m "Add pre-built dependencies" || echo "No changes to commit"
    git push "https://${GIT_TOKEN}@github.com/voalvu/fast_tiebaclone.git" HEAD:main -f
    touch .vendor_committed
  fi
fi

# Build main binary
echo "=== Compiling application ==="
mkdir -p public
# Compile as position-independent executable
gcc -fPIE -o public/tieba tieba.c \
  -I./vendor/include \
  -L./vendor/lib \
  -lmicrohttpd \
  -lpthread \
  -static

# Create vercel function wrapper
cat > public/index.sh <<EOF
#!/bin/bash
exec ./tieba
EOF

chmod +x public/tieba public/index.sh