-- spec/error_spec.lua
-- Error handling tests

describe("lol_html error handling", function()
    local lol_html
    
    setup(function()
        lol_html = require "lua.resty.lol_html"
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
    
    it("should not be usable after finalized", function()
        local rewriter = lol_html.new()
        rewriter:finalize()
        
        assert.has_error(function()
            rewriter:transformer("<div>test</div>")
        end)
        
        rewriter:free()
    end)
    
    it("should handle empty strings", function()
        local rewriter = lol_html.new()
        
        local output = rewriter:transformer("")
        local final = rewriter:finalize()
        
        assert.equals("", output)
        assert.equals("", final)
        
        rewriter:free()
    end)
    
    it("multiple free calls should be safe", function()
        local rewriter = lol_html.new()
        
        -- Multiple free calls should not crash
        rewriter:free()
        rewriter:free()
        rewriter:free()
    end)
    
end)
