#!/bin/bash
set -e

# Install Emscripten
if [ ! -d "emsdk" ]; then
  git clone https://github.com/emscripten-core/emsdk.git
  cd emsdk
  ./emsdk install latest
  ./emsdk activate latest
  source ./emsdk_env.sh
  cd ..
fi

# Build with WASM-compatible flags
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
  -s FILESYSTEM=0 \
  -s DYNAMIC_EXECUTION=0 \
  -s STRICT=1 \
  -O3

echo "Built WASM module to api/tieba.mjs"