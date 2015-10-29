local modulename = "AccessLayerMysql"
local _M = {}

_M._VERSION = '0.0.1'

local mysql = require('resty.mysql')

_M.new = function(self, conf)
    self.host       = conf.host
    self.port       = conf.port
    self.timeout    = conf.timeout
    self.poolsize   = conf.poolsize
    self.idletime   = conf.idletime
    self.database = conf.database
    self.user = conf.user
    self.password = conf.password
    self.max_packet_size = tonumber(conf.max_packet_size)

    local db = mysql:new()
    return setmetatable({mysql = db}, { __index = _M } )
end

_M.connectdb = function(self)
    local host  = self.host
    local port  = self.port
    local mysql = self.mysql
    local timeout = self.timeout
    local database = self.database
    local user = self.user
    local password = self.password
    local max_packet_size = self.max_packet_size

    if not (host and port and database and user and password) then
        return nil, 'missing necessary parameters when connecting mysql'
    end

    if not timeout then 
        timeout = 1000   -- 10s
    end
    mysql:set_timeout(timeout)

    local ok, err, errno, sqlstate = mysql:connect{
        host = host,
        port = port,
        database = database,
        user = user,
        password = password,
        max_packet_size = max_packet_size} 

    return ok, err, errno, sqlstate
end

_M.keepalivedb = function(self)
    local   pool_max_idle_time  = self.idletime --毫秒
    local   pool_size           = self.poolsize --连接池大小

    if not pool_size then pool_size = 1000 end
    if not pool_max_idle_time then pool_max_idle_time = 90000 end
    
    return self.mysql:set_keepalive(pool_max_idle_time, pool_size)  
end

return _M
