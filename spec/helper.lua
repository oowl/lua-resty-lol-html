-- spec/helper.lua
-- Test helper functions and setup

-- Ensure we can find our library
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Test helper functions
local M = {}

-- Create test HTML fragment
function M.create_test_html(links)
    local parts = {"<html><body>"}
    
    for i, link in ipairs(links) do
        table.insert(parts, string.format('<a href="%s">Link %d</a>', link, i))
    end
    
    table.insert(parts, "</body></html>")
    return table.concat(parts)
end


-- Test helper function for streaming processing
function M.process_chunks(rewriter, chunks)
    local outputs = {}
    
    for _, chunk in ipairs(chunks) do
        local output = rewriter:transformer(chunk)
        if output ~= "" then
            table.insert(outputs, output)
        end
    end
    
    local final = rewriter:finalize()
    if final ~= "" then
        table.insert(outputs, final)
    end
    
    return table.concat(outputs)
end

-- Performance test helper
function M.measure_time(func)
    local start_time = os.clock()
    local result = func()
    local end_time = os.clock()
    return result, (end_time - start_time)
end

return M
