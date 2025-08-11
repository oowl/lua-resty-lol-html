#!/usr/bin/env luajit

-- Example using lua-resty-lol-html (string input version)
local lol_html = require "lua.resty.lol_html"

-- Create new rewriter
local rewriter = lol_html.new()

-- Test HTML data - can be processed in chunks
local html_chunks = {
    '<div>',
    '<a href="http://example.com">',
    'Example Link',
    '</a>',
    '<a href="http://google.com">',
    'Google',
    '</a>',
    '</div>'
}

print("Starting HTML data processing...")
print("Input chunks:")
for i, chunk in ipairs(html_chunks) do
    print("  " .. i .. ": " .. chunk)
end
print("---")

-- Process HTML in chunks
local all_output = {}
for i, chunk in ipairs(html_chunks) do
    print("Processing chunk " .. i .. ": " .. chunk)
    local output = rewriter:transformer(chunk)
    
    if output ~= "" then
        print("-> Output: " .. output)
        table.insert(all_output, output)
    else
        print("-> (no output)")
    end
end

-- Finalize processing
local final_output = rewriter:finalize()
if final_output ~= "" then
    print("Final output: " .. final_output)
    table.insert(all_output, final_output)
end

-- Display complete results
print("---")
print("Complete conversion result:")
print(table.concat(all_output))
print("---")
print("Processing completed!")

-- Free resources (optional, as there's __gc metamethod)
rewriter:free()
