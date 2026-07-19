local self = require("openmw.self")

local consts = require("scripts.FollowerDetectionUtil.utils.consts")

local followers = {}

local function syncFollowerList(data)
    followers = data
end

return {
    eventHandlers = {
        FDU_SyncFollowerList = syncFollowerList,
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
