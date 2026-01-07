local followers = {}

local function updateFollowerList(data)
    followers = data.followers
end

return {
    eventHandlers = {
        FDU_UpdateFollowerList = updateFollowerList,
    },
    interfaceName = 'FollowerDetectionUtil',
    interface = {
        getFollowerList = function() return followers end,
    },
}
