local modulename = "AccessLayerInit"
local _M = {}

_M._VERSION = '0.0.1'

_M.mySqlConf = {
    ["host"]     = ngx.var.mysql_host,
    ["port"]     = tonumber(ngx.var.mysql_port),
    ["poolsize"] = tonumber(ngx.var.mysql_pool_size),
    ["idletime"] = tonumber(ngx.var.redis_keepalive_timeout) , 
    ["timeout"]  = tonumber(ngx.var.redis_connect_timeout),
    ["database"] = ngx.var.mysql_database,
    ["user"]     = ngx.var.mysql_user,
    ["password"] = ngx.var.mysql_password,
    ["max_packet_size"] = tonumber(ngx.var.mysql_max_packet_size),
}

_M.hmacSecretConf = {
    ["hmac_secret"] = ngx.var.hmac_secret,
}

_M.tokenExpireConf = {
    ["access_token_expire"] = tonumber(ngx.var.access_token_expire_time),
}

_M.tokenBucketConf = {
    ["rate"] = tonumber(ngx.var.token_bucket_rate),
    ["capacity"] = tonumber(ngx.var.token_bucket_capacity),
    ["shdict_expire"] = tonumber(ngx.var.shdict_expire),
}

return _M
