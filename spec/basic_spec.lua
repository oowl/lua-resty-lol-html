-- spec/basic_spec.lua
-- Basic functionality tests

local helper = require "spec.helper"

-- Verify the output contains expected links
local function assert_contains_https_links(output, expected_links)
    for i, link in ipairs(expected_links) do
        local https_link = link:gsub("^http:", "https:")
        assert.matches(https_link, output, string.format("Should contain converted link: %s", https_link))
    end
end

describe("lol_html basic functionality", function()
    local lol_html
    
    setup(function()
        lol_html = require "lua.resty.lol_html"
    end)
    
    it("create and destroy rewriter", function()
        local rewriter = lol_html.new()
        assert.is_not_nil(rewriter)
        rewriter:free()
    end)
    
    it("simple HTML processing", function()
        local rewriter = lol_html.new()
        local result = helper.process_chunks(rewriter, {"<div>Hello World</div>"})
        assert.equals("<div>Hello World</div>", result)
        rewriter:free()
    end)
    
    it("HTTP to HTTPS conversion", function()
        local rewriter = lol_html.new()
        local html = '<a href="http://example.com">Test</a>'
        local result = helper.process_chunks(rewriter, {html})
        
        assert.matches('href="https://example.com"', result)
        assert.matches('Test', result)
        rewriter:free()
    end)
    
    it("multiple link conversion", function()
        local rewriter = lol_html.new()
        local links = {"http://google.com", "http://github.com", "https://secure.com"}
        local html = helper.create_test_html(links)
        local result = helper.process_chunks(rewriter, {html})
        
        assert_contains_https_links(result, {"http://google.com", "http://github.com"})
        assert.matches('href="https://secure.com"', result) -- Already https URLs remain unchanged
        rewriter:free()
    end)
    
end)
