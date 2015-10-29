local modulename = 'AccessLayerErrorHandler'

local _M = { _VERSION = '0.01' }

local ERRORINFO = require('error.errcode').info

_M.handler = function(errinfo)
    local info 
    if type(errinfo) == 'table' then
        info = errinfo
    elseif type(errinfo) == 'string' then
        info = {ERRORINFO.LUA_RUNTIME_ERROR, errinfo}
    else
        info = {ERRORINFO.BLANK_INFO_ERROR, }
    end
    
    local errstack = debug.traceback()
    return {info, errstack}
end

_M.exitWithMsg = function(info,message)
    local status_code = info[1]
    ngx.status = status_code
    ngx.say(message)
    ngx.exit(status_code)
end

return _M
