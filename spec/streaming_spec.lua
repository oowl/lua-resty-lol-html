-- spec/streaming_spec.lua
-- Streaming processing tests

local helper = require "spec.helper"

describe("lol_html streaming processing", function()
    local lol_html
    
    setup(function()
        lol_html = require "lua.resty.lol_html"
    end)
    
    it("chunked HTML processing", function()
        local rewriter = lol_html.new()
        
        local chunks = {
            '<div>',
            '<a href="http://streaming.com">',
            'Streaming Link',
            '</a>',
            '</div>'
        }
        
        local result = helper.process_chunks(rewriter, chunks)
        
        assert.matches('<div>', result)
        assert.matches('href="https://streaming.com"', result)
        assert.matches('Streaming Link', result)
        assert.matches('</div>', result)
        
        rewriter:free()
    end)
    
    it("incomplete tag processing", function()
        local rewriter = lol_html.new()
        
        -- Simulate network packet fragmentation
        local chunks = {
            '<a hr',
            'ef="http://incomplete.com"',
            '>Incomplete Tag</a>'
        }
        
        local result = helper.process_chunks(rewriter, chunks)
        
        assert.matches('href="https://incomplete.com"', result)
        assert.matches('Incomplete Tag', result)
        
        rewriter:free()
    end)
    
    it("large data stream processing", function()
        local rewriter = lol_html.new()
        
        local chunks = {}
        -- Create 50 small fragments
        for i = 1, 50 do
            table.insert(chunks, string.format('<a href="http://link%d.com">Link %d</a>', i, i))
        end
        
        local result, duration = helper.measure_time(function()
            return helper.process_chunks(rewriter, chunks)
        end)
        
        -- Verify all links are correctly converted
        for i = 1, 50 do
            assert.matches(string.format('href="https://link%d.com"', i), result)
        end
        
        -- Performance check
        assert.is_true(duration < 0.5, string.format("Processing time: %.3f seconds", duration))
        
        rewriter:free()
    end)
    
end)
