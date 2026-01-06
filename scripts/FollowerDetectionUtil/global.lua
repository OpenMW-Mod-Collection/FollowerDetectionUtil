local world = require("openmw.world")
local core = require("openmw.core")

local followers = {}

local function updateFollowerList(data)
    local state = data.state
    -- irrelevant data filter
    local stateUnchanged = followers[state.actor.id] == state
    local randomBozo = not followers[state.actor.id] and not state.followsPlayer
    if stateUnchanged or randomBozo then return end

    followers[state.actor.id] = state

    -- broadcasting new follower list back to each actor
    for _, fState in pairs(followers) do
        fState.actor:sendEvent("FDU_UpdateFollowerList", { followers = followers })
    end

    for _, player in ipairs(world.players) do
        player:sendEvent("FDU_UpdateFollowerList", { followers = followers })
    end

    core.sendGlobalEvent("FDU_FollowerListUpdated", { followers = followers })
end

return {
    eventHandlers = {
        FDU_UpdateFollowerList = updateFollowerList
    },
    interfaceName = 'FollowerDetectionUtil',
    interface = {
        getFollowerList = function() return followers end,
    },
}
