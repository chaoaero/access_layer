local exitWithMsg = require('error.handler').exitWithMsg
local handler = require('error.handler').handler
local ERRORINFO	        = require('error.errcode').info
local utils             = require('utils.utils')
local cjson         = require('cjson.safe')
local systemConf    = require('utils.init')

local doresp = utils.doresp
local dolog = utils.dolog
local ngx_now = ngx.now()

local tokenBucketConf = systemConf.tokenBucketConf

-- If the number of tokens in bucket equals to the number of tokens per second, the burst rate will be the limit rate.

--local req = require "lua_script.comm.token_bucket_redis"
--local ok = req.limit{ key = ngx.var.remote_addr, zone = "ip", 
--                        rate = "2r/s", capacity = 10, log_level = ngx.ERROR,
--                        rds = { host = "127.0.0.1", port = 6379 }}
--if not ok then
--    return ngx.exit(503)
--end

local limit_req = require "lib.comm.token_bucket_shared_dict"

local lim, err = limit_req.new("my_limit_req_store", tokenBucketConf.rate, tokenBucketConf.capacity )
if not lim then
    local info = ERRORINFO.LUA_RUNTIME_ERROR
    local desc = "failed to initalized the limit req object"
    local response = doresp(info, desc)
    dolog(info, desc)
    exitWithMsg(info, response)
end

local key = require('args_info.ip').get()

local delay, err = lim:incoming(key, true)

if not delay and err == "rejected" then
    local info = ERRORINFO.REQUEST_FORBIDDEN
    local desc = "request speed is too fast"
    local response = doresp(info, desc)
    dolog(info, desc)
    exitWithMsg(info, response)
end

--
--if delay > 0 then
--    -- the 2nd return value holds  the number of excess requests
--    -- per second for the specified key. for example, number 31
--    -- means the current request rate is at 231 req/sec for the
--    -- specified key.
--    local excess = err
--
--    -- the request exceeding the 200 req/sec but below 300 req/sec,
--    -- so we intentionally delay it here a bit to conform to the
--    -- 200 req/sec rate.
--    ngx.say(delay)
--    ngx.sleep(delay)
--end
