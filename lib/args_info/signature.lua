
local _M = {
    _VERSION = '0.01'
}

_M.get = function()
	local u = ngx.req.get_headers()["X-Signature"]
	return u
end
return _M
