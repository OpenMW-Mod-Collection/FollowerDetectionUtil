---@diagnostic disable: undefined-doc-name
local omw_self = require("openmw.self")
local types = require("openmw.types")

---@class State
---@field leader types.NPC|types.Creature|nil
---@field superLeader types.NPC|types.Creature|nil
---@field followsPlayer boolean
local State = {}
State.__index = State

---@param leader unknown
---@return State
function State:new(leader)
    self = setmetatable({}, State)
    self:setLeader(leader)
    return self
end

function State:__tostring()
    local lines = {
        "State(",
        "  followsPlayer = " .. tostring(self.followsPlayer),
        "  leader        = " .. tostring(self.leader),
        "  superLeader   = " .. tostring(self.superLeader),
        ")",
    }
    return table.concat(lines, "\n")
end

---@param leader unknown
function State:setLeader(leader)
    self.leader = leader
    self.superLeader = nil
    self.followsPlayer = leader and leader.type == types.Player

    if leader then
        self.checkSuperLeader(self)
    end
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
        self.leader:sendEvent("Summoner_SetSuperLeaderMiddleware", { sender = omw_self })
    end
end

return State
