#!/bin/bash
set -ex

# Download and set up busybox
curl -LO https://www.busybox.net/downloads/binaries/1.35.0-x86_64-linux-musl/busybox
chmod +x busybox
ln -sf busybox cmp
ln -sf busybox diff
export PATH="$PATH:$(pwd)"

# Check for required utilities
command -v cmp >/dev/null && command -v diff >/dev/null || {
  echo "Missing required utilities"; exit 1
}

# Create directories
mkdir -p api public

# Install Emscripten with full setup
if [ ! -d "emsdk" ]; then
  echo "Installing Emscripten SDK..."
  git clone https://github.com/emscripten-core/emsdk.git
  cd emsdk
  ./emsdk install latest --permanent
  ./emsdk activate latest
  cd ..
fi

# Verify emsdk installation
if [ -f "emsdk/emsdk_env.sh" ]; then
  echo "Setting up Emscripten environment..."
  source emsdk/emsdk_env.sh
else
  echo "Emscripten installation failed!" >&2
  exit 1
fi

# Compile with verified paths
emcc tieba.c -o api/tieba.mjs \
  -s MODULARIZE=1 \
  -s EXPORT_ES6=1 \
  -s EXPORTED_FUNCTIONS='["_handle_request"]' \
  -s EXPORTED_RUNTIME_METHODS='["cwrap"]' \
  -s ENVIRONMENT=web \
  -s SINGLE_FILE=1 \
  -s WASM=1 \
  -s ALLOW_MEMORY_GROWTH=1 \
  -O3

# Create placeholder
touch public/.gitkeep
echo "Build successful"