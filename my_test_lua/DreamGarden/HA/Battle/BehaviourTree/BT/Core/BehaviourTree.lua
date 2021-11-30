---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by liuyubao.
--- DateTime: 2021/11/11 17:18
---
---@class BehaviourTree : MiddleClass
---@field _blackboard BehaviourTreeBlackboard
---@field _agent BehaviourTreeAgent
---@field _nodes BTNode[]
---@field _abilityContext BattleAbilityContext
local BehaviourTree = class("BehaviourTree")

function BehaviourTree:initialize(owner,contextManager)
    self._id = 0
    self._type = nil
    self._name = "BehaviourTree"
    --- 根节点
    self._rootNode = nil
    --- 根节点状态
    self._rootStatus = BT.Status.Resetting
    --- 节点词典
    --- dic <id,node>
    self._nodes = {}
    --- 节点ID List
    --- list [nodeId]
    self._nodesIndex = {}
    --- 包含得子树
    --- dic <id,BehaviourTree>
    self._subTrees = {}
    ---@type BehaviourTreeAgent
    self._agent = BT.BehaviourTreeAgent:new(owner)

    self._agent._isBTDebug = false
    ---@type BehaviourTreeBlackboard
    self._blackboard = BT.BehaviourTreeBlackboard:new(contextManager)

    ---是否在运行中
    self._isRunning = false

    --- 不知道
    self._tickCount = 0
    --- 是否打印信息
    self._isBTDebug = true
end

function BehaviourTree:start()
    self._isRunning = true
    self._rootStatus = self._rootNode._status
end

function BehaviourTree:update()
    if not self._isRunning then
        return
    end
    if self:tick(self._agent, self._blackboard) ~= BT.Status.Running and not self._isRepeat then
        self:stop(self._rootStatus == BT.Status.Success)
    end
end

function BehaviourTree:tick(agent, blackboard)
    if self._rootStatus ~= BT.Status.Running then
        self._tickCount = self._tickCount + 1
        self._rootNode:reset()
    end
    self._rootStatus = self._rootNode:execute(agent, blackboard)
    return self._rootStatus
end


function BehaviourTree:stop(success)
    if not self._isRunning then
        return
    end
    self._isRunning = false
    --for k, node in pairs(self._nodes) do
    --    node:reset(false)
    --end
    for _, nodeIndex in ipairs(self._nodesIndex) do
        self._nodes[nodeIndex]:reset(false)
    end
end

function BehaviourTree:reset()
end

function BehaviourTree:destroy()
    --for k, node in pairs(self._nodes) do
    --    node:destroy()
    --    node = nil
    --end
    for _, nodeIndex in ipairs(self._nodesIndex) do
        self._nodes[nodeIndex]:destroy()
        self._nodes[nodeIndex] = nil
    end
    self._nodes = nil
    self._nodesIndex = nil
end


function BehaviourTree:setOriginFillData(data)
    if not self._blackboard.OriginFillData and data then
        self._blackboard.OriginFillData = self:copy(data)
    end
end

function BehaviourTree:copy(t)
    local check_meta = function(val)
        if type(val) == 'table' then return true end
        return getmetatable(val)
    end

    local is_iterable = function(val)
        local mt = check_meta(val)
        if mt == true then return true end
        return mt and mt.__pairs and true
    end

    if not is_iterable(t) then
        error(('argument %d is not %s'):format(1,"iterable"),3)
    end

    local res = {}
    for k,v in pairs(t) do
        res[k] = v
    end
    return res
end

function BehaviourTree:loadNodes(fileName, fillData)
    -- print("......name..."..fileName)

end