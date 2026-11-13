---@omw-context global
local world = require("openmw.world")
local core = require("openmw.core")
local types = require("openmw.types")

local common = require("scripts.FollowerDetectionUtil.utils.common")
local Graph = require("scripts.FollowerDetectionUtil.model.graph")

local graph = Graph.new {
    isSummon = common.isSummon,
}

local followers = {}
local legacyEventData = { followers = followers }

local function notifyOtherScripts()
    for _, state in pairs(followers) do
        if state.actor:isValid() then
            state.actor:sendEvent("FDU_SyncFollowerList", followers)
            ---@deprecated
            state.actor:sendEvent("FDU_UpdateFollowerList", legacyEventData)
        end
    end

    for _, player in ipairs(world.players) do
        player:sendEvent("FDU_SyncFollowerList", followers)
        ---@deprecated
        player:sendEvent("FDU_UpdateFollowerList", legacyEventData)
    end

    core.sendGlobalEvent("FDU_SyncFollowerList", followers)
    ---@deprecated
    core.sendGlobalEvent("FDU_FollowerListUpdated", legacyEventData)
end

---@param changed State[]
---@param wasFollower table<string, boolean>
local function publish(changed, wasFollower)
    local listChanged = false
    local departing = {}

    for _, state in ipairs(changed) do
        local actor = state.actor
        local id = actor.id
        ---@diagnostic disable-next-line: undefined-field
        local wanted = state.depth > 0 and actor.enabled and actor:isValid()
        if wanted or followers[id] then
            followers[id] = state
            listChanged = true
            if not wanted then
                departing[#departing + 1] = id
            end
        end
    end

    if listChanged then
        notifyOtherScripts()
    end

    for _, id in ipairs(departing) do
        followers[id] = nil
    end

    for _, state in ipairs(changed) do
        local actor = state.actor

        if actor:isValid() and not types.Player.objectIsInstance(actor) then
            actor:sendEvent("FDU_SyncState", state)
        end

        if state.depth > 0 or wasFollower[actor.id] then
            core.sendGlobalEvent("FDU_FollowerStateUpdated", state)
        end
    end
end

---@param actor openmw.GObject
---@param leader openmw.GObject?
local function applyLeader(actor, leader)
    local changed, previous = graph:setLeader(actor, leader)
    if not changed then
        -- same leader as before
        -- the actor was loaded again and knows nothing yet
        if leader and actor:isValid() then
            actor:sendEvent("FDU_SyncState", graph:build(actor))
        end
        return
    end

    publish(graph:refresh(graph:affectedBy(actor, leader, previous)))
end

---@param data {actor: openmw.GObject, leader: openmw.GObject?}
local function leaderChanged(data)
    local actor, leader = data.actor, data.leader
    if not actor then
        return
    end

    if not actor.enabled then
        leader = nil
    end

    applyLeader(actor, leader)
end

return {
    eventHandlers = {
        FDU_LeaderChanged = leaderChanged,
    },
    interfaceName = "FollowerDetectionUtil",
    interface = {
        version = common.interfaceVersion,
        getFollowerList = function()
            return followers
        end,
        getFollowersOf = function(leader, recursive)
            return common.getFollowersOf(followers, leader, recursive)
        end,
        follows = common.follows,
        isSummon = common.isSummon,
    },
}
