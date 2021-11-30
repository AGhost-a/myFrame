
local string = string

---@class BT
local BT = {
    DeltaTime = 0,
    FrameCount = 1,
    Time = 0,
}
BT.Status = {
    Failure = 0,
    Success = 1,
    Running = 2,
    Resetting = 3,
    Error = 4,
    Optional = 5
}

function BT.getStatusInfo (status)
    if status == BT.Status.Failure then
        return "Failure"
    elseif status == BT.Status.Success then
        return "Success"
    elseif status == BT.Status.Running then
        return "Running"
    elseif status == BT.Status.Resetting then
        return "Resting"
    elseif status == BT.Status.Error then
        return "Error"
    elseif status == BT.Status.Optional then
        return "Optional"
    else
        return "Unkown:" .. status
    end
end

function BT.class(classname, ...)
    return class(classname,...)
end

function BT.getClass(clsPath)
    local type
    local Cls = nil

    for w in string.gmatch(clsPath, "([^'.']+)") do
        type = w
    end
    if BT[type] then
        Cls = BT[type]
    else
        print("ERROR:bt.getCls:invalid class,fullPath=" .. clsPath .. ",subPath=" .. type)
    end
    return Cls
end

return BT

