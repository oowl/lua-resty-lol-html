#!/bin/bash
set -e

# Script to run tests
echo "Starting lua-resty-lol-html tests..."

# Check if dynamic library exists
if [ ! -f "target/release/liblol_html_ffi.so" ]; then
    echo "Dynamic library does not exist, building..."
    cargo build --release
fi

# Check if busted is installed
if ! command -v busted &> /dev/null; then
    echo "Error: busted not found. Please install busted:"
    echo "  luarocks install busted"
    echo "Or on Ubuntu/Debian:"
    echo "  sudo apt-get install lua-busted"
    exit 1
fi

# Set up Lua paths
export LUA_PATH="./lua/?.lua;./lua/?/init.lua;$LUA_PATH"

# Check if we're in CI environment
if [ "$CI" = "true" ]; then
    echo "Running in CI environment"
    # Use gtest output format for CI
    OUTPUT_FORMAT="gtest"
else
    echo "Running locally"
    # Use verbose output for local development
    OUTPUT_FORMAT="verbose"
fi

# Run tests
echo "Running tests with $OUTPUT_FORMAT output..."
if [ "$OUTPUT_FORMAT" = "gtest" ]; then
    busted -o gtest spec/
else
    busted --verbose spec/
fi

echo "Tests completed!"

# Optional: Run the example to make sure everything works
echo "Running example..."
luajit example.lua || echo "Example run failed (this might be expected if LuaJIT is not available)"
