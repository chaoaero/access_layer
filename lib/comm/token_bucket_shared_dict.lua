-- Copyright (C) Weichao Meng (chaoaero)
--
-- This library is an approximate Lua port of the standard ngx_limit_req using token bucket algorithms.
-- The main idea derives from https://github.com/openresty/lua-resty-limit-traffic


local ffi = require "ffi"
local math = require "math"


local ngx_shared = ngx.shared
local ngx_now = ngx.now
local setmetatable = setmetatable
local ffi_cast = ffi.cast
local ffi_str = ffi.string
local abs = math.abs
local min = math.min
local tonumber = tonumber
local type = type


ffi.cdef[[
    struct lua_resty_limit_req_rec {
        unsigned long        last;  /* time in milliseconds */
        /* integer value, 1 corresponds to 0.001 r/s */
        unsigned long       tokens;
    };
]]

local const_rec_ptr_type = ffi.typeof("const struct lua_resty_limit_req_rec*")
local rec_size = ffi.sizeof("struct lua_resty_limit_req_rec")

-- we can share the cdata here since we only need it temporarily for
-- serialization inside the shared dict:
local rec_cdata = ffi.new("struct lua_resty_limit_req_rec")


local _M = {
    _VERSION = '0.01'
}


local mt = {
    __index = _M
}


function _M.new(dict_name, rate, capacity)
    local dict = ngx_shared[dict_name]
    if not dict then
        return nil, "shared dict not found"
    end

    assert(rate > 0 and capacity >= 0)

    local self = {
        dict = dict,
        rate = rate * 1000,
        capacity = capacity * 1000,
    }

    return setmetatable(self, mt)
end

function _M.incoming(self, key, commit)
    local dict = self.dict
    local rate = self.rate
    local now = ngx_now() * 1000

    local tokens = self.rate
    local excess 

    local v = dict:get(key)
    if v then
        if type(v) ~= "string" or #v ~= rec_size then
            return nil, "shdict abused by other users"
        end
        local rec = ffi_cast(const_rec_ptr_type, v)
        local elapsed = now - tonumber(rec.last)
        tokens = tonumber(rec.tokens)

        if tokens < self.capacity then
            local delta = self.rate * abs(elapsed) / 1000
            tokens = min(self.capacity, tokens + delta)
        end

        if tokens < 1000 then
            if commit then
                rec_cdata.tokens = tokens
                rec_cdata.last = now
                dict:set(key, ffi_str(rec_cdata, rec_size))
            end
            return nil, "rejected"
        end

        tokens = tokens - 1000
    end

    if commit then
        rec_cdata.tokens = tokens
        rec_cdata.last = now
        dict:set(key, ffi_str(rec_cdata, rec_size))
    end

    -- return the delay in seconds, as well as excess
    -- If we use token bucket algorithms, the excess value is the one that how many tokens that we need to catch up with the ordinary number of tokens: rate.
    if  tokens < self.rate then
        excess = self.rate - tokens 
    else
        excess = 0
    end

    return excess / rate, excess / 1000
end


function _M.uncommit(self, key)
    assert(key)
    local dict = self.dict

    local v = dict:get(key)
    if not v then
        return nil, "not found"
    end

    if type(v) ~= "string" or #v ~= rec_size then
        return nil, "shdict abused by other users"
    end

    local rec = ffi_cast(const_rec_ptr_type, v)

    local tokens = tonumber(rec.tokens) + 1000
    if tokens > self.capacity then
        tokens = self.capacity
    end

    rec_cdata.tokens = tokens
    rec_cdata.last = rec.last
    dict:set(key, ffi_str(rec_cdata, rec_size))
    return true
end


function _M.set_rate(self, rate)
    self.rate = rate * 1000
end

function _M.set_capacity(self, capacity)
    self.capacity = capacity * 1000
end

return _M
