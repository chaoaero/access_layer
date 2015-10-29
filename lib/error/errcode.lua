local modulename = 'ErrorInfo'
local _M = {}

_M._VERSION = '0.0.1'

_M.info = {
    --	index			    code    desc
    --	SUCCESS
    ["SUCCESS"]			= { 200,   'success '},
    
    --	System Level ERROR
    ['MYSQL_ERROR']		= { 401, 'mysql error for '},
  
    ['LUA_RUNTIME_ERROR']	= { 402, 'lua runtime error '},
    ['BLANK_INFO_ERROR']	= { 402, 'errinfo blank in handler '},

    -- request forbidden
    ['REQUEST_FORBIDDEN'] = {403, 'invalid request for '},

    --	Service Level ERROR
    --	input or parameter error
    ['PARAMETER_NONE']		= { 501, 'expected parameter for '},
    ['PARAMETER_ERROR']		= { 501, 'parameter error for '},
    ['PARAMETER_NEEDED']	= { 501, 'need parameter for '},
    ['PARAMETER_TYPE_ERROR']	= { 501, 'parameter type error for '},
    
   -- mysql result error
    ['MYSQL_NO_RESULT_ERROR'] = {502, 'mysql bad result error for'},
    ['ACCESS_TOKEN_ERROR'] = {502, 'Invalid user for '},
     
    --	mysql connect error
    ['MYSQL_CONNECT_ERROR']	= { 503, 'mysql connect error for '},
    ['MYSQL_KEEPALIVE_ERROR']   = { 503, 'mysql keepalive error for '},
    
    --  unknown reason
    ['UNKNOWN_ERROR']		= { 505, 'unknown reason '},
}

return _M
