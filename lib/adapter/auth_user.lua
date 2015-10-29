local modulename = "AccessLayerAdaperAuthUser"
local thirdparty = require('comm.thirdparty')

local _M = { _VERSION = "0.0.1" }
local mt = { __index = _M }

local ERRORINFO	= require('error.errcode').info

---
--- auth user new function
-- @param database opened mysql.
_M.new = function(self, database, tableName)
    if not database then
        error{ERRORINFO.PARAMETER_NONE, 'need avaliable mysql db'}
    end
    if not tableName then
        error{ERRORINFO.PARAMETER_NONE, 'need avaliable table name'}
    end
    
    self.database  = database
    self.tableName = tableName
    
    return setmetatable(self, mt)
end

_M.getByAccessToken = function(self, access_token)
    if not access_token then
        return nil
    end
    local access_token = ngx.quote_sql_str(access_token)
    local database      = self.database
    local tableName     = self.tableName

    local res, err, errno, sqlstate = database:query("select * from auth_user where access_token = " .. access_token)

    if not res then
        error{ERRORINFO.MYSQL_NO_RESULT_ERROR, err}
    end

    return res
end

return _M
