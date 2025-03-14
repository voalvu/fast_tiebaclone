#!/bin/bash
set -ex

# Download and set up busybox
curl -LO https://www.busybox.net/downloads/binaries/1.35.0-x86_64-linux-musl/busybox
chmod +x busybox
ln -sf busybox cmp
ln -sf busybox diff
export PATH="$PATH:$(pwd)"

# Check for required utilities
if ! command -v cmp >/dev/null 2>&1 || ! command -v diff >/dev/null 2>&1; then
  echo "Error: cmp/diff not found"
  exit 1
fi

# Create Vercel directories
mkdir -p api public

# Emscripten installation with validation
if [ ! -f "emsdk/emsdk_env.sh" ]; then
  echo "Installing Emscripten SDK..."
  rm -rf emsdk  # Clean incomplete installations
  git clone https://github.com/emscripten-core/emsdk.git
  cd emsdk
  ./emsdk install latest
  ./emsdk activate latest
  cd ..
fi

# Always activate and source in correct context
cd emsdk
source ./emsdk_env.sh
cd ..

# Compile to WebAssembly
echo "Compiling tieba.c..."
emcc tieba.c -o api/tieba.mjs \
  -s MODULARIZE=1 \
  -s EXPORT_ES6=1 \
  -s EXPORTED_FUNCTIONS='["_handle_request"]' \
  -s EXPORTED_RUNTIME_METHODS='["cwrap","UTF8ToString"]' \
  -s ENVIRONMENT='web,worker,shell' \
  -s SINGLE_FILE=1 \
  -s ASSERTIONS=1 \
  -s ALLOW_MEMORY_GROWTH=1 \
  -O3
# Create public content
touch public/.gitkeep
echo "Build successful"