#!/bin/bash

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
    exit 1
fi

# Run tests
echo "Running tests..."
busted --verbose

echo "Tests completed!"
