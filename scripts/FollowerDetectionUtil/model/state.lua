local omw_self = require("openmw.self")
local types = require("openmw.types")
local core = require("openmw.core")
local I = require("openmw.interfaces")

---@class State
---@field actor GameObject
---@field leader GameObject|nil
---@field superLeader GameObject|nil
---@field followsPlayer boolean
local State = {}
State.__index = State

---@param leader any
---@return State
function State:new(leader)
    self = setmetatable({}, State)
    self.actor = omw_self
    self:setLeader(leader)
    return self
end

---@return string
function State:__tostring()
    local lines = {
        "State(",
        "  actor         = " .. tostring(self.actor),
        "  followsPlayer = " .. tostring(self.followsPlayer),
        "  leader        = " .. tostring(self.leader),
        "  superLeader   = " .. tostring(self.superLeader),
        ")",
    }
    return table.concat(lines, "\n")
end

---@param x GameObject
---@return string|nil
local function eqId(x)
    return x and x.id or nil
end

---@param a State
---@param b State
---@return boolean
function State:__eq(a, b)
    return eqId(a.actor)       == eqId(b.actor)
       and eqId(a.leader)      == eqId(b.leader)
       and eqId(a.superLeader) == eqId(b.superLeader)
       and a.followsPlayer     == b.followsPlayer
end

function State:updateFollowerList()
    print(tostring(self))
    core.sendGlobalEvent("FDU_UpdateFollowerList", {
        state = self
    })
end

---@param leader GameObject
function State:setLeader(leader)
    if leader == self.leader then return end
    -- skip first update to initialize the script first
    if not I.FollowerDetectionUtil then return end

    self.leader = leader
    self.followsPlayer = leader and types.Player.objectIsInstance(leader) or false
    self:setSuperLeader()

    self:updateFollowerList()
end

function State:setSuperLeader()
    if not self.leader then
        self.superLeader = nil
        return
    end

    local followerList = I.FollowerDetectionUtil.getFollowerList()
    local leaderState = followerList[self.leader.id]

    if leaderState and leaderState.leader then
        self.superLeader = leaderState.leader
        self.followsPlayer = types.Player.objectIsInstance(leaderState)
    else
        self.superLeader = nil
    end
end

return State
