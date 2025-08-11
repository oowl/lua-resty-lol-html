-- spec/lol_html_spec.lua
-- Test file using busted testing framework

local lol_html = require "lua.resty.lol_html"

describe("lua-resty-lol-html", function()
    
    describe("basic functionality", function()
        it("should be able to create new rewriter", function()
            local rewriter = lol_html.new()
            assert.is_not_nil(rewriter)
            assert.is_table(rewriter)
            rewriter:free()
        end)
        
        it("should be able to process simple HTML strings", function()
            local rewriter = lol_html.new()
            local output = rewriter:transformer("<div>Hello</div>")
            local final = rewriter:finalize()
            rewriter:free()
            
            -- Simple HTML should pass through directly
            local complete_output = output .. final
            assert.equals("<div>Hello</div>", complete_output)
        end)
    end)
    
    describe("HTTP to HTTPS conversion", function()
        it("should convert single http link to https", function()
            local rewriter = lol_html.new()
            
            local html_parts = {
                '<a href="http://example.com">',
                'Link',
                '</a>'
            }
            
            local outputs = {}
            for _, part in ipairs(html_parts) do
                local output = rewriter:transformer(part)
                if output ~= "" then
                    table.insert(outputs, output)
                end
            end
            
            local final = rewriter:finalize()
            if final ~= "" then
                table.insert(outputs, final)
            end
            
            local complete_output = table.concat(outputs)
            assert.matches('href="https://example.com"', complete_output)
            assert.matches('Link', complete_output)
            
            rewriter:free()
        end)
        
        it("should convert multiple http links", function()
            local rewriter = lol_html.new()
            
            local html = '<a href="http://google.com">Google</a><a href="http://github.com">GitHub</a>'
            local output = rewriter:transformer(html)
            local final = rewriter:finalize()
            
            local complete_output = output .. final
            assert.matches('href="https://google.com"', complete_output)
            assert.matches('href="https://github.com"', complete_output)
            
            rewriter:free()
        end)
        
        it("should not affect already https links", function()
            local rewriter = lol_html.new()
            
            local html = '<a href="https://secure.com">Secure</a>'
            local output = rewriter:transformer(html)
            local final = rewriter:finalize()
            
            local complete_output = output .. final
            assert.matches('href="https://secure.com"', complete_output)
            assert.matches('Secure', complete_output)
            
            rewriter:free()
        end)
        
        it("should not affect relative links", function()
            local rewriter = lol_html.new()
            
            local html = '<a href="/relative/path">Relative</a>'
            local output = rewriter:transformer(html)
            local final = rewriter:finalize()
            
            local complete_output = output .. final
            assert.matches('href="/relative/path"', complete_output)
            assert.matches('Relative', complete_output)
            
            rewriter:free()
        end)
    end)
    
    describe("streaming processing", function()
        it("should support chunked input", function()
            local rewriter = lol_html.new()
            
            local html_parts = {
                '<div>',
                '<a href="http://streaming.com">',
                'Streaming Link',
                '</a>',
                '</div>'
            }
            
            local outputs = {}
            for _, part in ipairs(html_parts) do
                local output = rewriter:transformer(part)
                if output ~= "" then
                    table.insert(outputs, output)
                end
            end
            
            local final = rewriter:finalize()
            if final ~= "" then
                table.insert(outputs, final)
            end
            
            local complete_output = table.concat(outputs)
            assert.matches('<div>', complete_output)
            assert.matches('href="https://streaming.com"', complete_output)
            assert.matches('Streaming Link', complete_output)
            assert.matches('</div>', complete_output)
            
            rewriter:free()
        end)
        
        it("should correctly handle incomplete tags", function()
            local rewriter = lol_html.new()
            
            -- Simulate network streaming reception
            local parts = {
                '<a hr',
                'ef="http://incomplete.com">',
                'Incomplete Link',
                '</a>'
            }
            
            local outputs = {}
            for _, part in ipairs(parts) do
                local output = rewriter:transformer(part)
                if output ~= "" then
                    table.insert(outputs, output)
                end
            end
            
            local final = rewriter:finalize()
            if final ~= "" then
                table.insert(outputs, final)
            end
            
            local complete_output = table.concat(outputs)
            assert.matches('href="https://incomplete.com"', complete_output)
            assert.matches('Incomplete Link', complete_output)
            
            rewriter:free()
        end)
    end)
    
    describe("error handling", function()
        it("should throw error after rewriter finalized", function()
            local rewriter = lol_html.new()
            
            rewriter:finalize()
            
            assert.has_error(function()
                rewriter:transformer("<div>test</div>")
            end)
            
            rewriter:free()
        end)
        
        it("should reject non-string input", function()
            local rewriter = lol_html.new()
            
            assert.has_error(function()
                rewriter:transformer(123)
            end)
            
            assert.has_error(function()
                rewriter:transformer({})
            end)
            
            assert.has_error(function()
                rewriter:transformer(nil)
            end)
            
            rewriter:free()
        end)
        
        it("should handle empty strings gracefully", function()
            local rewriter = lol_html.new()
            
            local output = rewriter:transformer("")
            local final = rewriter:finalize()
            
            assert.equals("", output)
            assert.equals("", final)
            
            rewriter:free()
        end)
    end)
    
    describe("resource management", function()
        it("should not crash on multiple free calls", function()
            local rewriter = lol_html.new()
            
            -- Multiple free calls should not crash
            rewriter:free()
            rewriter:free()
            rewriter:free()
        end)
        
        it("should properly clean up resources", function()
            -- Create multiple rewriters and ensure they clean up
            for i = 1, 10 do
                local rewriter = lol_html.new()
                rewriter:transformer("<div>test</div>")
                rewriter:finalize()
                rewriter:free()
            end
        end)
    end)
    
    describe("performance testing", function()
        it("should handle large inputs efficiently", function()
            local rewriter = lol_html.new()
            
            -- Create a large HTML string with multiple links
            local parts = {}
            for i = 1, 100 do
                table.insert(parts, string.format('<a href="http://link%d.com">Link %d</a>', i, i))
            end
            local large_html = table.concat(parts)
            
            local start_time = os.clock()
            local output = rewriter:transformer(large_html)
            local final = rewriter:finalize()
            local end_time = os.clock()
            
            local duration = end_time - start_time
            
            -- Should complete within reasonable time
            assert.is_true(duration < 1.0, string.format("Processing took too long: %.3f seconds", duration))
            
            -- Verify all links were converted
            local complete_output = output .. final
            for i = 1, 100 do
                assert.matches(string.format('href="https://link%d.com"', i), complete_output)
            end
            
            rewriter:free()
        end)
    end)
    
end)
