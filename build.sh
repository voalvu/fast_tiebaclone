#!/bin/bash
set -ex

rm -rf emsdk
curl -LO https://www.busybox.net/downloads/binaries/1.35.0-x86_64-linux-musl/busybox
chmod +x busybox
ln -sf busybox cmp
ln -sf busybox diff
export PATH="$PATH:$(pwd)"

command -v cmp >/dev/null && command -v diff >/dev/null || { echo "Missing required utilities"; exit 1; }
mkdir -p api public

echo "Installing Emscripten SDK..."
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
git pull
./emsdk install latest --permanent
./emsdk activate latest
cd ..

if [ -f "emsdk/emsdk_env.sh" ]; then
  source "$PWD/emsdk/emsdk_env.sh"
else
  echo "Emscripten installation failed!" >&2
  exit 1
fi

emcc tieba.c -o api/tieba.mjs \
  -s MODULARIZE=1 \
  -s EXPORT_ES6=1 \
  -s USE_ES6_IMPORT_META=0 \  # Add this line
  -s EXPORTED_FUNCTIONS='["_handle_request"]' \
  -s EXPORTED_RUNTIME_METHODS='["cwrap"]' \
  -s ENVIRONMENT=web,worker \  # Changed from just 'worker'
  -s SINGLE_FILE=1 \
  -s WASM_ASYNC_COMPILATION=1 \
  -s ALLOW_MEMORY_GROWTH=1 \
  -s ASSERTIONS=1 \
  -O3

touch public/.gitkeep
echo "Build successful"