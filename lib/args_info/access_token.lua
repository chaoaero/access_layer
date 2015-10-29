
local _M = {
    _VERSION = '0.01'
}

_M.get = function()
    local access_token , TokenStr
    local raw_token_str = ngx.req.get_headers()["Authorization"] 
    if not raw_token_str then
        return nil
    end
    TokenStr, access_token = raw_token_str:match("Token(%s+)(%S+)")
    if not access_token then
        return nil
    end
    return access_token
end


return _M
