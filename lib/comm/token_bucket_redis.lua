local tonumber = tonumber


local _M = { _VERSION = "0.01", OK = 1, FORBIDDEN = 2 }


local redis_limit_req_script_sha
local redis_limit_req_script = [==[
local key = KEYS[1]
local rate = tonumber(KEYS[2])
local now, capacity = tonumber(KEYS[3]), tonumber(KEYS[4])
local timestamp, tokens
local res, err = redis.pcall('GET', key)
if not res then
    
    local res, err = redis.pcall('SETEX', key, 86400, cjson.encode({ rate, rate ,capacity , now}))
    if not res then
        return {err = err}
    end
    return cjson.encode({status = true, message = "the value is not in redis"})
end

local v = cjson.decode(res)
if v and #v > 3 then
    rate, tokens, capacity, timestamp = v[1], v[2], v[3], v[4]
else
    return {err = "invalid data format in redis"}
end

if tokens < capacity then
    -- local delta = rate * math.floor(now - timestamp)
    local delta = rate * (now - timestamp)
    tokens = math.min(capacity, tokens + delta)
end

local ttl = redis.call('TTL', key)

timestamp = now
if tokens < 1 then
    local res, err = redis.pcall('SETEX', key,ttl, cjson.encode({rate, tokens, capacity, timestamp}))
    if not res then
        return {err = err}
    end
    return cjson.encode({status = false, err = "not enough tokens for this request" })
end

tokens = tokens - 1

local res, err = redis.pcall('SETEX', key, ttl, cjson.encode({rate, tokens, capacity, timestamp}))
if not res then
    return {err = err}
end

return cjson.encode({status = true, message = tokens})

]==]


local function redis_lookup(conn, zone, key, rate, capacity)
    local red = conn

    --The Lua interpreter or LuaJIT instance is shared across all the requests in a single nginx worker process but request contexts are segregated using lightweight Lua coroutines.
    --Loaded Lua modules persist in the nginx worker process level resulting in a small memory footprint in Lua even when under heavy loads.
    if not redis_limit_req_script_sha then
        local res, err = red:script("LOAD", redis_limit_req_script)
        if not res then
            return nil, err
        end

        ngx.log(ngx.NOTICE, "load redis limit req script=======================================================")

        redis_limit_req_script_sha = res
    end

    local now = ngx.now()

    local res, err = red:evalsha(redis_limit_req_script_sha, 4, zone .. ":" .. key, rate, now, capacity)
    if not res then
        redis_limit_req_script_sha = nil
        return nil, err
    end

    -- put it into the connection pool of size 100,
    -- with 10 seconds max idle timeout
    local ok, err = red:set_keepalive(10000, 100)
    if not ok then
        ngx.log(ngx.WARN, "failed to set keepalive: ", err)
    end

    return res
end

function _M.limit(cfg)
    if not cfg.conn then
        local ok, redis = pcall(require, "resty.redis")
        if not ok then
            ngx.log(ngx.ERR, "failed to require redis")
            return _M.OK
        end

        local rds = cfg.rds or {}
        rds.timeout = rds.timeout or 1
        rds.host = rds.host or "127.0.0.1"
        rds.port = rds.port or 6379

        local red = redis:new()

        red:set_timeout(rds.timeout * 1000)

        local ok, err = red:connect(rds.host, rds.port)
        if not ok then
            ngx.log(ngx.WARN, "redis connect err: ", err)
            return _M.OK
        end

        cfg.conn = red
    end

    local conn = cfg.conn
    local zone = cfg.zone or "limit_req"
    local key = cfg.key or ngx.var.remote_addr
    local rate = cfg.rate or "1r/s"
    local log_level = cfg.log_level or ngx.INFO

    local scale = 1
    local len = #rate
    
    if len > 3 and rate:sub(len - 2) == "r/s" then
        scale = 1
        rate = rate:sub(1, len - 3)
    elseif len > 3 and rate:sub(len - 2) == "r/m" then
        scale = 60
        rate = rate:sub(1, len - 3)
    end

    rate = (tonumber(rate) or 1) / scale
    local capacity = cfg.capacity
    local res, err = redis_lookup(conn, zone, key, rate, capacity)
    if res then
        local json_res = cjson.decode(res)
        ngx.log(ngx.NOTICE,json_res.message)
        if json_res.status then
            ngx.log(ngx.NOTICE, "request speed of zone: " .. zone .." key: " .. key .." is allowed")
            return _M.OK
        else
            return _M.FORBIDDEN
        end
    elseif err then
        ngx.log(ngx.WARN, "redis lookup err: ", err)
    end

    return _M.OK
end


return _M
