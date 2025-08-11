#!/usr/bin/env luajit

-- Test FFI string input version
local ffi = require "ffi"

-- C function declarations
ffi.cdef[[
    typedef struct RewriterWrapper RewriterWrapper;
    
    RewriterWrapper* html_rewriter_new();
    int html_rewriter_transform_string(RewriterWrapper* wrapper, const char* input, size_t input_len, char** output, size_t* output_len);
    int html_rewriter_finalize(RewriterWrapper* wrapper, char** output, size_t* output_len);
    void html_rewriter_free(RewriterWrapper* wrapper);
    void html_rewriter_free_string(char* ptr);
]]

-- Load dynamic library
local lib = ffi.load("./target/release/liblol_html_ffi.so")

print("=== Test HTML Rewriter FFI (String Version) ===")

-- Create rewriter
local rewriter = lib.html_rewriter_new()
if rewriter == nil then
    error("Failed to create rewriter")
end
print("✓ Rewriter created successfully")

-- Test data - chunked processing
local html_chunks = {
    '<div>',
    '<a href="http://example.com">',
    'Test Link',
    '</a>',
    '</div>'
}

print("Input HTML chunks:")
for i, chunk in ipairs(html_chunks) do
    print("  " .. i .. ": " .. chunk)
end

-- Process each string chunk
local all_output = {}
for i, chunk in ipairs(html_chunks) do
    print("Processing chunk " .. i .. ": " .. chunk)
    
    local output_ptr = ffi.new("char*[1]")
    local output_len = ffi.new("size_t[1]")
    
    local result = lib.html_rewriter_transform_string(
        rewriter, 
        chunk, 
        #chunk,
        output_ptr, 
        output_len
    )
    
    if result == 1 then
        local output_str = ffi.string(output_ptr[0], output_len[0])
        table.insert(all_output, output_str)
        lib.html_rewriter_free_string(output_ptr[0])
        print("-> Output: " .. output_str)
    elseif result == -1 then
        error("Failed to process chunk " .. i)
    else
        print("-> (no output)")
    end
end

-- Finalize processing
local output_ptr = ffi.new("char*[1]")
local output_len = ffi.new("size_t[1]")
local result = lib.html_rewriter_finalize(rewriter, output_ptr, output_len)

if result == 1 then
    local final_output = ffi.string(output_ptr[0], output_len[0])
    table.insert(all_output, final_output)
    lib.html_rewriter_free_string(output_ptr[0])
    print("Final output: " .. final_output)
elseif result == -1 then
    error("Failed to finalize")
end

-- Free rewriter
lib.html_rewriter_free(rewriter)

-- Display complete results
local complete_output = table.concat(all_output)
print("---")
print("Complete conversion result: " .. complete_output)
print("✓ Test completed!")
