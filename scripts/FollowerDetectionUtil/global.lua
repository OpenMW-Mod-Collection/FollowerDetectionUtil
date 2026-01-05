local world = require("openmw.world")
local core = require("openmw.core")

local followers = {}

local function updateFollowerList(data)
    -- irrelevant data filter
    local stateUnchanged = followers[data.senderId] == data.state
    local randomBozo = not followers[data.senderId] and not data.state.followsPlayer
    if stateUnchanged or randomBozo then return end

    followers[data.senderId] = data.state

    -- broadcasting new follower list back to each actor
    for follower, _ in pairs(followers) do
        follower:sendEvent("FDU_UpdateFollowerList", { followers = followers })
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
