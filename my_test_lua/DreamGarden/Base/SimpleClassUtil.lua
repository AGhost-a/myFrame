
local SimpleClassUtil = {}

---@private
function SimpleClassUtil.new(cls, ...)
    local t = setmetatable({}, cls)
    local f = t.initialize
    if f then
        f(t, ...)
    end
    return t
end


---@param super SimpleClass
function SimpleClassUtil:class(super)
    local cls = {}
    cls.__index = cls
    cls.new = self.new
    if super then
        cls.super = super
        return setmetatable(cls, super)
    end
    return cls
end

--if LuaMacro.UNITY_EDITOR then
--    -------------------------------------------
--    ---@class SimpleClass
--    ---@field protected super SimpleClass
--    local mn = {}
--
--    ---@protected
--    function mn:initialize(...) end
--
--    function mn:new(...) end
--end

return SimpleClassUtil
