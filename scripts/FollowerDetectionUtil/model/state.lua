---@diagnostic disable: undefined-field
---@omw-context local
local omw_self = require("openmw.self")
local core = require("openmw.core")

local common = require("scripts.FollowerDetectionUtil.utils.common")

---@class State
---@field actor openmw.self
---@field leader openmw.GObject? Who the actor follows directly
---@field leaders openmw.GObject[] Whole chain, nearest first: `leaders[1] == leader`, `leaders[2] == superLeader`, ...
---@field superLeader openmw.GObject? @deprecated Alias for `leaders[2]`
---@field rootLeader openmw.GObject? The last actor of the chain, `leaders[#leaders]`
---@field depth integer Length of the chain: 0 - follows nobody, 1 - follows someone, 2 - follows a follower, ...
---@field followers openmw.GObject[] Actors who follow this actor directly
---@field isSummon boolean
---@field followsPlayer boolean `true` if the player is anywhere in the chain
local State = {}
State.__index = State

---@param leader openmw.GObject?
---@return State
function State:new(leader)
    local state = setmetatable({}, State)
    state.actor = omw_self
    state.isSummon = common.isSummon(omw_self.recordId)
    state.leaders = {}
    state.superLeader = nil
    state.depth = 0
    state.followers = {}
    state.followsPlayer = false
    state:setLeader(leader)
    return state
end

---@param list openmw.GObject[]
---@return string
local function idList(list)
    local ids = {}
    for i, o in ipairs(list) do
        ids[i] = o.id
    end
    return table.concat(ids, ",")
end

---@return string
function State:__tostring()
    local lines = {
        "State(",
        "  actor         = " .. tostring(self.actor),
        "  followsPlayer = " .. tostring(self.followsPlayer),
        "  leader        = " .. tostring(self.leader),
        "  superLeader   = " .. tostring(self.superLeader),
        "  isSummon      = " .. tostring(self.isSummon),
        "  rootLeader    = " .. tostring(self.rootLeader),
        "  depth         = " .. tostring(self.depth),
        "  leaders       = [" .. idList(self.leaders) .. "]",
        "  followers     = [" .. idList(self.followers) .. "]",
        ")",
    }
    return table.concat(lines, "\n")
end

---@param x openmw.GObject
---@return string?
local function eqId(x)
    return x and x.id or nil
end

---@param a State
---@param b State
---@return boolean
function State.__eq(a, b)
    ---@diagnostic disable-next-line: param-type-mismatch
    return eqId(a.actor) == eqId(b.actor)
        and eqId(a.leader) == eqId(b.leader)
        and eqId(a.superLeader) == eqId(b.superLeader)
        and idList(a.leaders) == idList(b.leaders)
        and idList(a.followers) == idList(b.followers)
        and a.followsPlayer == b.followsPlayer
end

---@param leader openmw.GObject?
function State:setLeader(leader)
    if leader == self.leader then
        return
    end
    self.leader = leader
    self:updateFollowerList()
end

function State:updateFollowerList()
    core.sendGlobalEvent("FDU_LeaderChanged", {
        actor = self.actor,
        leader = self.leader,
    })
end

---@param data State
function State:sync(data)
    if eqId(data.leader) ~= eqId(self.leader) then
        return
    end

    self.leaders = data.leaders
    self.superLeader = data.superLeader or (self.leaders[2] or nil)
    self.rootLeader = data.rootLeader
    self.depth = data.depth
    self.followers = data.followers
    self.followsPlayer = data.followsPlayer
end

return State
