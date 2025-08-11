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

-- Load dynamic library (adjust path as needed)
local lib = ffi.load("./target/release/liblol_html_ffi.so")

local _M = {}

-- Create new HTML rewriter
function _M.new()
    local rewriter_ptr = lib.html_rewriter_new()
    if rewriter_ptr == nil then
        error("Failed to create HTML rewriter")
    end
    
    return {
        _ptr = rewriter_ptr,
        _finalized = false
    }
end

-- Transform string data
function _M.transformer(self, input_string)
    if self._finalized then
        error("Rewriter has been finalized")
    end
    
    if type(input_string) ~= "string" then
        error("Input must be a string")
    end
    
    local output_ptr = ffi.new("char*[1]")
    local output_len = ffi.new("size_t[1]")
    
    local result = lib.html_rewriter_transform_string(
        self._ptr, 
        input_string, 
        #input_string, 
        output_ptr, 
        output_len
    )
    
    if result == -1 then
        error("Failed to transform string")
    elseif result == 1 then
        -- Has output
        local output_str = ffi.string(output_ptr[0], output_len[0])
        lib.html_rewriter_free_string(output_ptr[0])
        return output_str
    else
        -- No output
        return ""
    end
end

-- Finalize processing
function _M.finalize(self)
    if self._finalized then
        return ""
    end
    
    self._finalized = true
    
    local output_ptr = ffi.new("char*[1]")
    local output_len = ffi.new("size_t[1]")
    
    local result = lib.html_rewriter_finalize(self._ptr, output_ptr, output_len)
    
    if result == -1 then
        error("Failed to finalize rewriter")
    elseif result == 1 then
        local output_str = ffi.string(output_ptr[0], output_len[0])
        lib.html_rewriter_free_string(output_ptr[0])
        return output_str
    else
        return ""
    end
end

-- Free resources
function _M.free(self)
    if not self._finalized then
        self:finalize()
    end
    
    if self._ptr ~= nil then
        lib.html_rewriter_free(self._ptr)
        self._ptr = nil
    end
end

-- Metatable for automatic resource cleanup
local mt = {
    __index = _M,
    __gc = function(self)
        self:free()
    end
}

-- Wrap new function to add metatable
local original_new = _M.new
function _M.new()
    local obj = original_new()
    return setmetatable(obj, mt)
end

return _M
