#!/bin/bash
set -ex

# Download and set up busybox
curl -LO https://www.busybox.net/downloads/binaries/1.35.0-x86_64-linux-musl/busybox
chmod +x busybox
ln -sf busybox cmp
ln -sf busybox diff
export PATH="$PATH:$(pwd)"

# Check for required utilities (cmp and diff)
if ! command -v cmp >/dev/null 2>&1 || ! command -v diff >/dev/null 2>&1; then
  echo "Error: cmp and diff utilities are required. Please install diffutils using 'pacman -Syu' followed by 'pacman -S diffutils' in MINGW64."
  exit 1
fi

# Create required Vercel directories
mkdir -p api public

# Install and configure Emscripten SDK if not already present
if [ ! -d "emsdk" ]; then
  echo "Cloning Emscripten SDK..."
  git clone https://github.com/emscripten-core/emsdk.git
  cd emsdk
  echo "Installing latest Emscripten..."
  ./emsdk install latest
  echo "Activating latest Emscripten..."
  ./emsdk activate latest
  cd ..
fi

# Ensure the Emscripten environment is sourced
if [ -f "emsdk/emsdk_env.sh" ]; then
  echo "Sourcing Emscripten environment..."
  source emsdk/emsdk_env.sh
else
  echo "Error: emsdk/emsdk_env.sh not found. Emscripten SDK setup failed."
  exit 1
fi

# Compile the C code to WebAssembly
echo "Compiling tieba.c to WebAssembly..."
emcc tieba.c -o api/tieba.mjs \
  -s MODULARIZE=1 \
  -s EXPORT_ES6=1 \
  -s EXPORTED_FUNCTIONS='["_handle_request"]' \
  -s EXPORTED_RUNTIME_METHODS='["cwrap"]' \
  -s ENVIRONMENT='web,worker,shell' \
  -s SINGLE_FILE=1 \
  -s ASSERTIONS=2 \
  -s ALLOW_MEMORY_GROWTH=1 \
  -O3

# Create minimal public content (can be empty)
touch public/.gitkeep

echo "Build complete"