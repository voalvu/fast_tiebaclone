#!/bin/bash
set -ex

# Create required Vercel directories
mkdir -p api public

# Rest of your existing build script
if [ ! -d "emsdk" ]; then
  git clone https://github.com/emscripten-core/emsdk.git
  cd emsdk
  ./emsdk install latest
  ./emsdk activate latest
  source ./emsdk_env.sh
  cd ..
fi

source emsdk/emsdk_env.sh

emcc tieba.c -o api/tieba.mjs \
  -s MODULARIZE=1 \
  -s EXPORT_ES6=1 \
  -s EXPORTED_FUNCTIONS='["_handle_request"]' \
  -s EXPORTED_RUNTIME_METHODS='["cwrap"]' \
  -s ENVIRONMENT='web,worker,shell' \  # Added 'shell'
  -s SINGLE_FILE=1 \
  -s ASSERTIONS=2 \  # Increased to 2 for better error messages
  -s ALLOW_MEMORY_GROWTH=1 \
  -O3

# Create minimal public content (can be empty)
touch public/.gitkeep

echo "Build complete"