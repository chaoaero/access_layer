local exitWithMsg = require('error.handler').exitWithMsg
local handler = require('error.handler').handler
local mysqlModule       = require('utils.mysql')
local ERRORINFO	        = require('error.errcode').info
local utils             = require('utils.utils')
local authUserModule    = require('adapter.auth_user')
local cjson         = require('cjson.safe')
local systemConf    = require('utils.init')
local thirdparty = require('comm.thirdparty')

local doresp = utils.doresp
local dolog = utils.dolog
local ngx_now = ngx.now()

local mySqlConf = systemConf.mySqlConf
local tokenExpireConf = systemConf.tokenExpireConf

local isNULL = function(v)
    return not v or v == ngx.null
end

local mysql
local setKeepalive = function(mysql)
    local ok, err = mysql:keepalivedb()
    if not ok then
        local errinfo = ERRORINFO.MYSQL_KEEPALIVE_ERROR
        local errdesc = err
        dolog(errinfo, errdesc)
        return
    end
end

local tokenStore = ngx.shared.my_access_token_store
local access_token = require('args_info.access_token').get()

if not access_token then
    local info = ERRORINFO.PARAMETER_NONE
    local desc = "missing require parameter: timestamp"
    local response = doresp(info, desc)
    dolog(info, desc)
    exitWithMsg(info, response)
end

local token_exipre = tokenExpireConf.access_token_expire

local user_id = tokenStore:get(access_token) 

if isNULL(user_id) then
    -- first we query mysql and write the result back to shared dict
    mysql = mysqlModule:new(mySqlConf)
    local ok, err, errno, sqlstate = mysql:connectdb()
    if not ok then
        local err_info = ERRORINFO.MYSQL_CONNECT_ERROR
        local desc = "unkown reasons"
        local response = doresp(err_info, desc)
        dolog(err_info, err, errno)
        exitWithMsg(err_info, response)
    end

    local pfunc = function()
        local authUserMod = authUserModule:new(mysql.mysql,"auth_user") 
        local auth_user = authUserMod:getByAccessToken(access_token)
        return auth_user
    end

    local status, info = xpcall(pfunc, handler)
    if not status then
        local errinfo  = info[1]
        local errstack = info[2]
        local err, desc = errinfo[1], errinfo[2]
        local response = doresp(errinfo)
        dolog(err, desc, errstack)
        exitWithMsg(errinfo, response)
    end

    if thirdparty.table_is_empty(info) then
        local err_info = ERRORINFO.MYSQL_NO_RESULT_ERROR
        local desc = "The user cannot be found"
        local response = doresp(err_info, desc)
        dolog(err_info, desc)
        exitWithMsg(err_info, response)
    end

    local auth_user = info[1]

    local u_time = thirdparty.make_time_stamp(auth_user.utime)
    local expire_time = tokenExpireConf.access_token_expire
    if ngx_now - u_time > expire_time then
        local err_info = ERRORINFO.ACCESS_TOKEN_ERROR
        local desc = "The token is overdue"
        local response = doresp(err_info, desc)
        dolog(err_info, desc)
        exitWithMsg(err_info, response)
    end

    -- write result back to shared dict
    tokenStore:set(access_token, auth_user.uid, expire_time)
end

if mysql then
    setKeepalive(mysql)
end
