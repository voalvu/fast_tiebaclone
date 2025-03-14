#!/bin/bash
set -ex

# Install Emscripten
if [ ! -d "emsdk" ]; then
  git clone https://github.com/emscripten-core/emsdk.git
  cd emsdk
  ./emsdk install latest
  ./emsdk activate latest
  source ./emsdk_env.sh
  cd ..
fi

# Build WASM module
source emsdk/emsdk_env.sh
mkdir -p api

emcc tieba.c -o api/tieba.mjs \
  -s MODULARIZE=1 \
  -s EXPORT_ES6=1 \
  -s EXPORTED_FUNCTIONS='["_handle_request"]' \
  -s EXPORTED_RUNTIME_METHODS='["cwrap"]' \
  -s ENVIRONMENT='web,worker' \
  -s SINGLE_FILE=1 \
  -s ASSERTIONS=1 \
  -O3

echo "Build complete"