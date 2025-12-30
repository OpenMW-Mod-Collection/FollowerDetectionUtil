---@diagnostic disable: undefined-doc-name
local omw_self = require("openmw.self")
local types = require("openmw.types")

---@class State
---@field leader types.Actor|nil
---@field superLeader types.Actor|nil
---@field followsPlayer boolean
local State = {}
State.__index = State

---@param leader unknown
---@return State
function State:new(leader)
    self = setmetatable({}, State)
    self.leader = leader
    self.superLeader = nil
    self.followsPlayer = leader and leader.type == types.Player
    return self
end

---@param leader unknown
function State:setLeader(leader)
    self.leader = leader
    self.followsPlayer = leader and leader.type == types.Player
end

function State:setSuperLeader(superLeader)
    self.superLeader = superLeader
    self.followsPlayer = superLeader and superLeader.type == types.Player
end

function State:checkSuperLeader()
    local isSummon = string.find(omw_self.recordId, "_summon$")
        or string.find(omw_self.recordId, "_summ$")

    if not self.followsPlayer and isSummon then
        ---@diagnostic disable-next-line: undefined-field
        self.leader:sendEvent("Summon_CheckSummonersLeader", { sender = omw_self })
    end
end

---@return State
function InitState()
    local leader = GetLeader()
    if not leader then return State:new(nil) end

    local state = State:new(leader)
    state:checkSuperLeader()

    return state
end
