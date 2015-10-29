-- thirdparty.lua
--  meta-methods usage: http://lua-users.org/wiki/MetamethodsTutorial
local _M = { _VERSION = '0.01'} 
local mt = { __index = _M }

function  _M.table_is_empty(t)
    return next(t) == nil
end

function _M.table_is_array(t)
    if type(t) ~= "table" then return false end
    local i = 0
    for _ in pairs(t) do
        i = i + 1
        if t[i] == nil then return false end
    end
    return true
end

function _M.table_is_map(t)
    if type(t) ~= "table" then return false end
    for k,_ in pairs(t) do
        if type(k) == "number" then  return false end
    end
    return true
end

-- mysql date format: 2015-09-22 18:28:24
function _M.make_time_stamp(dateString)
    local pattern = "(%d+)%-(%d+)%-(%d+) (%d+):(%d+):(%d+)"
    local xyear, xmonth, xday, xhour, xminute, xsecond = dateString:match(pattern)
    local convertedTimestamp = os.time({year = xyear, month = xmonth, 
        day = xday, hour = xhour, min = xminute, sec = xsecond})
    -- local offset = xoffsethour * 60 + xoffsetmin
    -- if xoffset == "-" then offset = offset * -1 end
    return convertedTimestamp
end

-- judge string is empty
function _M.isempty(s)
    return s == nil or s == ''
end

return _M
