local thirdparty = require "lib.comm.thirdparty"
local str = require "resty.string"
local resty_hmac = require "lib.comm.hmac"
local exitWithMsg = require('error.handler').exitWithMsg
local handler = require('error.handler').handler
local ERRORINFO	        = require('error.errcode').info
local utils             = require('utils.utils')
local cjson         = require('cjson.safe')
local systemConf    = require('utils.init')

local doresp = utils.doresp
local dolog = utils.dolog
local req_method = ngx.req.get_method()

local hmac_secret = systemConf.hmacSecretConf.hmac_secret

local abs = math.abs
local sort = table.sort

local isNULL = function(v)
    return not v or v == ngx.null or v == ""
end

local req_signature = ngx.header["X-Signature"]

if req_method == "POST" then
    req_args = ngx.req.get_post_args()
else
    req_args = ngx.req.get_uri_args()
end

local req_timestamp = req_args["timestamp"]

if isNULL(req_timestamp) then
    local err_info = ERRORINFO.PARAMETER_NEEDED
    local desc = "missing timestamp parameter"
    local response = doresp(err_info, desc)
    dolog(err_info, err, errno)
    exitWithMsg(err_info, response)
end

local req_signature = require('args_info.signature').get()
if isNULL(req_timestamp) then
    local err_info = ERRORINFO.PARAMETER_NEEDED
    local desc = "missing signature header"
    local response = doresp(err_info, desc)
    dolog(err_info, err, errno)
    exitWithMsg(err_info, response)
end

local diff_ts = abs(req_timestamp - ngx.now()) 
if diff_ts > 300 then
    local err_info = ERRORINFO.REQUEST_FORBIDDEN
    local desc = "invalid timestamp parameters"
    local response = doresp(err_info, desc)
    dolog(err_info, err, errno)
    exitWithMsg(err_info, response)
end

-- valid timestamp case
-- Compute the HMAC_MD5 signature
local StringToSign = "" 
local sorted_tbl = {}
for n in pairs(req_args) do
    if not thirdparty.isempty(req_args[n]) then
        sorted_tbl[#sorted_tbl + 1] = n
    end
end

sort(sorted_tbl)

for k, v in pairs(sorted_tbl) do
    StringToSign = StringToSign .. v .. req_args[v] 
end
local hmac = resty_hmac:new(hmac_secret)
hmac:update(StringToSign)
local signature = string.upper(str.to_hex(hmac:final()))
hmac:cleanup()

if signature ~= req_signature then
    local err_info = ERRORINFO.REQUEST_FORBIDDEN
    local desc = "invalid signature headers"
    local response = doresp(err_info, desc)
    dolog(err_info, err, errno)
    exitWithMsg(err_info, response)
end

