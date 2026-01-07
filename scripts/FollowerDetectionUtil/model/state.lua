local omw_self = require("openmw.self")
local types = require("openmw.types")
local core = require("openmw.core")
local I = require("openmw.interfaces")

---@class State
---@field actor any|nil
---@field leader any|nil
---@field superLeader any|nil
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

---Has to be called only after all the events get fired!
function State:updateFollowerList()
    core.sendGlobalEvent("FDU_UpdateFollowerList", {
        state = self
    })
end

---@param leader any
function State:setLeader(leader)
    if leader and not leader:isValid() then
        self.setLeader(self, nil)
    end

    if leader == self.leader then return end

    self.leader = leader
    self.followsPlayer = leader and leader.type == types.Player or false
    self.setSuperLeader(self)

    self.updateFollowerList(self)
end

function State:setSuperLeader()
    -- skip 1 frame to initialize the script first
    if not I.FollowerDetectionUtil then
        self.leader = nil
        return
    end

    local followerList = I.FollowerDetectionUtil.getFollowerList()

    local superLeader = followerList[self.leader.id]
    if not superLeader or not superLeader:isValid() then
        self.superLeader = nil
        return
    end

    self.superLeader = superLeader
    self.followsPlayer = superLeader and superLeader.type == types.Player or false
end

return State
