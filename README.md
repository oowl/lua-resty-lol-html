# lua-resty-lol-html

LuaJIT FFI bindings for lol_html - fast HTML rewriter.

## Features

- Convert HTTP links to HTTPS
- Stream processing of HTML data
- Memory efficient string processing
- Automatic resource management

## Build

```bash
# Build release version
cargo build --release

# After compilation, dynamic library files will be generated:
# target/release/liblol_html_ffi.so (Linux)
# target/release/liblol_html_ffi.dylib (macOS) 
# target/release/lol_html_ffi.dll (Windows)
```

## Usage

### Basic Example

```lua
local lol_html = require "lua.resty.lol_html"

-- Create new rewriter
local rewriter = lol_html.new()

-- HTML data
local html = '<a href="http://example.com">Link</a>'

-- Process HTML string
local output = rewriter:transformer(html)
if output ~= "" then
    print(output)
end

-- Get final output
local final = rewriter:finalize()
if final ~= "" then
    print(final)
end
```

### API

#### `lol_html.new()`
Create a new HTML rewriter instance.

**Returns:** rewriter object

#### `rewriter:transformer(input_string)`
Process a string and return the converted output.

**Parameters:**

- `input_string` - HTML string to process

**Returns:** converted string, empty string if no output

#### `rewriter:finalize()`
Complete processing and return final output. The rewriter cannot be used after calling this.

**Returns:** final output string

#### `rewriter:free()`
Manually free resources. Usually not needed due to automatic garbage collection.

## Running the Example

```bash
# First build the library
cargo build --release

# Then run the example (requires LuaJIT)
luajit example.lua
```

## Dependencies

- Rust (for building)
- LuaJIT (for running)
- lol_html crate

## License

MIT

## Testing

This project uses the [busted](https://lunarmodules.github.io/busted/) testing framework.

### Install Test Dependencies

```bash
# Install busted
luarocks install busted

# Or use system package manager (Ubuntu/Debian)
sudo apt-get install lua-busted
```

### Running Tests

```bash
# Use the provided script
./run_tests.sh

# Or use busted directly
busted

# Run specific test file
busted spec/basic_spec.lua

# Verbose output
busted --verbose
```

### Test Structure

```
spec/
├── helper.lua          # Test helper functions
├── basic_spec.lua      # Basic functionality tests
├── streaming_spec.lua  # Streaming processing tests
├── error_spec.lua      # Error handling tests
└── lol_html_spec.lua   # Complete test suite
```

### Test Coverage

- ✅ Basic HTML processing
- ✅ HTTP to HTTPS link conversion
- ✅ Streaming/chunked data processing
- ✅ Error handling and edge cases
- ✅ Resource management and memory safety
- ✅ Performance testing

### CI/CD

You can use the following command in continuous integration:

```bash
# Build and test
cargo build --release && busted --output=json
```
