local world = require("openmw.world")

local followers = {}

local function updateFollowerList(data)
    followers[data.sender] = data.state

    for follower, _ in pairs(followers) do
        follower:sendEvent("FDU_UpdateFollowerList", { followers = followers })
    end

    for _, player in ipairs(world.players) do
        player:sendEvent("FDU_UpdateFollowerList", { followers = followers })
    end
end

return {
    eventHandlers = {
        FDU_UpdateFollowerList = updateFollowerList
    }
}