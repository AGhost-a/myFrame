--[[
   FileName: Logger.lua
   Author: panyupin@topjoy.com
   Date: 2019-03-29 09:33:51
   Desc: 封装lua的log，能设定哪个log等级打印，哪个等级带stack信息等
--]]
---@class Logger
local Logger = {}

Logger.PREFIX = "LUA: "
Logger.Exception = "LuaException: "

local unpack = unpack or table.unpack

local unityLog
local unityWarn
local unityError
local logEnabled = true
local csLogType

local ConsoleProDebug
local printOrig = print
local tostring = tostring

local csBattleLogType = CS.TKW.Battle.LogType

if true then
    unityLog = CS.UnityEngine.Debug.Log
    unityWarn = CS.UnityEngine.Debug.LogWarning
    unityError = CS.UnityEngine.Debug.LogError
    csLogType = CS.UnityEngine.LogType
    ConsoleProDebug = CS.ConsoleProDebug
else
    unityLog = printOrig
    unityWarn = printOrig
    unityError = printOrig
    csLogType = CS.TKW.Battle.LogType
    ConsoleProDebug = {
        Watch = function(tag, str)
            printOrig(string.format("%s, %s", tostring(tag), tostring(str)))
        end
    }
end


---@generic V : number
---@type table<string, V>
local LogLevel = {
    ["print"] = 1,
    ["warning"] = 2,
    ["assert"] = 3,
    ["error"] = 4
}

local _level_to_name = {}
for k, v in pairs(LogLevel) do
    _level_to_name[v] = k
end

local luaLogLv2CsLogType = {csLogType.Log, csLogType.Warning, csLogType.Assert, csLogType.Error}
local luaLogLv2CsBattleLogType = {csBattleLogType.Log, csBattleLogType.Warning, csBattleLogType.Assert, csBattleLogType.Error}

local curLogLevel = LogLevel.print
local curStackLevel = LogLevel.warning

local MAX_TABLE_DEEP = 8

-- 循环打印table
---@generic V : any
---@param str string @ 最后总的msg
---@param key string @ 要打印的tbl的key （当tbl在其他table中出现的时候）
---@param tbl table<string, V>
---@param ex string @ 是行首缩进
---@param layer number @ 当前递归深度
---@param repeate table @ 用来判断某个table是否要被重复打印
local function printTable(key, tbl, str, ex, layer, repeate)
    local childTable = {}

    ---@type string
    local nextEx = ex .. "\t"
    if key then
        --  如果tbl是在其他table中出现
        -- 打印{
        str = string.format("%s%s[%s]={ (%s)", str, ex, key, tostring(tbl))
    else
        -- tbl是要打印的初始的table
        -- 打印{
        str = string.format("%s%s{ (%s)", str, ex, tostring(tbl))
    end

    -- 如果tbl非空
    if next(tbl) then
        local isFull = layer >= MAX_TABLE_DEEP
        for k, v in pairs(tbl) do
            if type(v) ~= "table" or isFull then
                str = string.format("%s\n%s[%s](%s) = (%s)%s, ", str, nextEx, k, type(v), tostring(v), type(v))
            else
                -- 是table，而且没有isFull

                -- 判断是否打印过此table
                if repeate[v] then
                    str = string.format("%s\n%s[%s] = %s(repeate), ", str, nextEx, k, tostring(v))
                else
                    childTable[k] = v
                end
            end
        end

        --printOrig("printTable"..str.."  1"..layer.." max:"..MAX_TABLE_DEEP)
        -- 打印table类型的孩子
        for k, v in pairs(childTable) do
            repeate[v] = true
            ---@generic V
            ---@type table<string, V>
            local vv = v
            str = printTable(k, vv, str .. "\n", nextEx, layer + 1, repeate)
        end
        str = str .. "\n" .. ex .. "},"
    else
        str = str .. " },"
    end

    return str
end

local function makeLuaLogString(...)
    local count = select("#", ...)
    local args = {...}
    local str = Logger.PREFIX
    -- 不能用ipairs/pairs遍历
    for i = 1, count do
        local v = args[i]
        if type(v) ~= "table" then
            str = string.format("%s%s\t", str, tostring(v))
        elseif v == nil then
            str = string.format("%s%s\t", str, "nil")
        else
            -- table类型
            str = string.format("%s\n{", str)
            for k, v in pairs(v) do
                str = string.format("%s[%s]=%s,  \n", str, k, tostring(v))
            end
            str = string.format("%s}", str)
        end
    end
    return str
end

--- 支持打印一层表的print，参数里没有表则跟原print一致
--- @param printFunc function @ 实际打印的函数
local function printExt(printFunc, ...)
    local str = makeLuaLogString(...)
    printFunc(str)
end

-- 新的print
-- 有curLogLevel, curStackLevel控制
-- 添加traceback

function Logger.print(...)
    if (not logEnabled) or curLogLevel > LogLevel.print then
        return
    end

    if curStackLevel > LogLevel.print then
        printExt(unityLog, ...)
    else
        local count = select("#", ...)
        local args = {...}
        -- 这里traceback有参数会使mobdebug异常
        table.insert(args, "\n" .. debug.traceback())
        printExt(unityLog, unpack(args, 1, count + 1))
    end
end

-- 使用printExt
-- warning级日志
function Logger.warning(...)
    if (not logEnabled) or curLogLevel > LogLevel.warning then
        return
    end

    if curStackLevel > LogLevel.warning then
        printExt(unityWarn, ...)
    else
        local count = select("#", ...)
        local args = {...}
        -- 这里traceback有参数会使mobdebug异常
        table.insert(args, "\n" .. debug.traceback())
        printExt(unityWarn, unpack(args, 1, count + 1))
    end
end

-- 使用printExt
-- error级日志
function Logger.error(...)
    if (not logEnabled) or curLogLevel > LogLevel.error then
        return
    end

    if curStackLevel > LogLevel.error then
        printExt(unityError, ...)
    else
        -- 这里traceback有参数会使mobdebug异常
        local str = makeLuaLogString(...)
        unityError(str .. "\n" .. debug.traceback())
    end
end

-- 使用printExt
-- error级日志
function Logger.assert(v, ...)
    if v then
        return
    end
    -- if (not logEnabled) or curLogLevel > LogLevel.error then
    --     return
    -- end
    local str = makeLuaLogString(...)
    assert(v, str .. "\n" .. debug.traceback())
end

function Logger.filter(tag, ...)
    if (not logEnabled) or curLogLevel > LogLevel.print then
        return
    end
    local count = select("#", ...)
    local args = {...}
    local str = ""
    -- 不能用ipairs/pairs遍历
    for i = 1, count do
        local v = args[i]
        if type(v) == "table" then
            -- table类型
            str = string.format("%s{", str)
            for v_k, v_v in pairs(v) do
                str = string.format("%s[%s]=%s, ", str, v_k, tostring(v_v))
            end
            str = string.format("%s}, ", str)
        else
            str = string.format("%s%s, ", str, tostring(v))
        end
    end
    if curStackLevel > LogLevel.print then
        unityLog(string.format("#%s# %s", tag, str))
    else
        unityLog(string.format("#%s# %s\n%s", tag, str, debug.traceback()))
    end
end

function Logger.watch(tag, ...)
    if (not logEnabled) or curLogLevel > LogLevel.print then
        return
    end
    local count = select("#", ...)
    local args = {...}
    local str = ""
    -- 不能用ipairs/pairs遍历
    for i = 1, count do
        local v = args[i]
        if type(v) == "table" then
            -- table类型
            str = string.format("%s{", str)
            for v_k, v_v in pairs(v) do
                str = string.format("%s[%s]=%s, ", str, v_k, tostring(v_v))
            end
            str = string.format("%s}, ", str)
        else
            str = string.format("%s%s, ", str, tostring(v))
        end
    end
    ConsoleProDebug.Watch(tag, str)
end

--- 更改日志输出等级
---@param levelStr string | '"print"' | '"warning"' | '"assert"' | '"error"'
function Logger.setLogLevel(levelStr)
    local v = LogLevel[levelStr]
    if v ~= nil then
        curLogLevel = v
        local csType = luaLogLv2CsLogType[v]
        if GameMode == GameModeDefine.BattleServer then
            -- ServerBattleLog.filterInFile = csType
            return
        end
        local instance = CS.Topjoy.Tkw.Loggers.LoggerBehavour.Instance

        if GameMode == GameModeDefine.Client then
            if instance then
                instance.fileFilter = csType
            end
        elseif GameMode == GameModeDefine.Editor then
            print("此时不启动文件log", GameMode, levelStr)
        else
            error("unhandeld game mode", GameMode, levelStr)
        end

        if instance then
            instance.consoleFilter = csType
        end
    else
        unityError("wrong log level:" .. levelStr)
    end
end

--- 更改日志添加调用栈的等级
---@param levelStr string | '"print"' | '"warning"' | '"assert"' | '"error"'
function Logger.setStackLevel(levelStr)
    local v = LogLevel[levelStr]
    if v ~= nil then
        --CS.Topjoy.Engine.Loggers.LoggerBehavour.Instance.LogFileHandler.stackTraceInFile = luaLogLv2CsLogType[v]
        curStackLevel = v
    else
        unityError("wrong stack level:" .. levelStr)
    end
end

function Logger.getLogLevel()
    return _level_to_name[curLogLevel]
end

function Logger.getStackLevel()
    return _level_to_name[curStackLevel]
end

---@param n number
---@return string
function Logger.levelIntToName(n)
    return _level_to_name[n]
end

---@param name string
---@return number
function Logger.levelNameToInt(name)
    return LogLevel[name]
end

local function spaceStr(tabNum)
    local ret = ""
    for i=1, tabNum do
        ret = string.format("%s%s", ret, "    ")
    end
    return ret
end

local function dumpLuaLog(data, tabNum)
    local str = ""
    if data == nil then
        str = string.format("%s", "nil")
    elseif type(data) ~= "table" then
        if type(data) == "string" then
            str = string.format("\"%s\"", data)
        elseif type(data) == "boolean" then
            str = string.format("%s", tostring(data))
        elseif type(data) == "number" then
            str = string.format("%d", data)
        elseif type(data) == "function" then
            str = string.format("function:%s", tostring(data))
        elseif type(data) == "thread" then
            str = string.format("thread:%s", tostring(data))
        else
            str = string.format("%s", "nil")
        end
    else
        -- table类型
        str = string.format("%s{\n", str)
        -- 进行排序
        local sortMap = {}
        for k, v in pairs(data) do
            sortMap[#sortMap+1] = k
        end
        if #data == #sortMap then -- 数组
            for i=1, #data do
                if i~=#data then
                    str = string.format("%s%s%s,\n", str,spaceStr(tabNum), dumpLuaLog(data[i], tabNum+1))
                else
                    str = string.format("%s%s%s", str,spaceStr(tabNum), dumpLuaLog(data[i], tabNum+1))
                end
            end
        else
            table.sort(sortMap)
            for i=1, #sortMap do
                if i ~= #sortMap then
                    str = string.format("%s%s[\"%s\"]=%s,\n", str, spaceStr(tabNum),sortMap[i], dumpLuaLog(data[sortMap[i]], tabNum+1))
                else
                    str = string.format("%s%s[\"%s\"]=%s", str, spaceStr(tabNum),sortMap[i], dumpLuaLog(data[sortMap[i]], tabNum+1))
                end
            end
        end
        str = string.format("%s\n%s}", str,spaceStr(tabNum-1))
    end

    return str
end

---@param v boolean
function Logger.enableLog(v)
    CS.Topjoy.Base.Loggers.LoggerUtil.logEnabled = v
    logEnabled = v
end

function Logger.isEnableLog()
    return logEnabled
end

function Logger.printd(...)
    if (not logEnabled) or curLogLevel > LogLevel.print then
        return
    end

    local count = select("#", ...)
    local args = {...}
    -- 这里traceback有参数会使mobdebug异常
    table.insert(args, "\n" .. debug.traceback())
    printExt(unityLog, unpack(args, 1, count + 1))
end

Logger.printd = Logger.print

return Logger
