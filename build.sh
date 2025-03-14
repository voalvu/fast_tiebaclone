#!/bin/bash
set -e

# Check if Emscripten is available
if ! command -v emcc >/dev/null 2>&1; then
    echo "Emscripten not found. Installing..."
    # Install Emscripten (minimal setup for this script)
    git clone https://github.com/emscripten-core/emsdk.git || true
    cd emsdk
    ./emsdk install latest
    ./emsdk activate latest
    source ./emsdk_env.sh
    cd ..
fi

# Ensure output directory exists
mkdir -p api

# Compile to WebAssembly with optimizations
emcc -o api/tieba.js tieba.c \
    -s EXPORTED_FUNCTIONS='["_handle_request"]' \
    -s EXPORTED_RUNTIME_METHODS='["cwrap"]' \
    -s ENVIRONMENT='web' \
    -s SINGLE_FILE=1 \
    -O3

echo "WASM compiled to api/tieba.js (includes embedded .wasm)"