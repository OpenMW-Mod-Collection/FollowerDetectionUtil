local world = require("openmw.world")
local core = require("openmw.core")

local consts = require("scripts.FollowerDetectionUtil.utils.consts")

local followers = {}
local legacyEventData = { followers = followers }

local function notifyOtherScripts()
    for _, fState in pairs(followers) do
        fState.actor:sendEvent("FDU_SyncFollowerList", followers)
        ---@deprecated
        fState.actor:sendEvent("FDU_UpdateFollowerList", legacyEventData)
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

local function followerStateUpdated(state)
    -- if duplicate
    if followers[state.actor.id] == state then return end

    followers[state.actor.id] = state
    notifyOtherScripts()

    if not state.followsPlayer or not state.actor.enabled then
        followers[state.actor.id] = nil
    end
end

return {
    eventHandlers = {
        FDU_FollowerStateUpdated = followerStateUpdated
    },
    interfaceName = 'FollowerDetectionUtil',
    interface = {
        version = consts.interfaceVersion,
        getFollowerList = function() return followers end,
        follows = function(fState, potentialLeader)
            return (fState.leader and fState.leader.id == potentialLeader.id)
                or (fState.superLeader and fState.superLeader.id == potentialLeader.id)
        end,
    },
}
