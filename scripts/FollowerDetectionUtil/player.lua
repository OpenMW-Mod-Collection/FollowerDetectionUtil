local followers = {}

---The best option we have for AI packet updates
---@param data table { actor = types.Actor, targets = targets }
local function targetsChanged(data)
    data.actor:sendEvent("FDU_ReInitState")
end

local function updateFollowerList(data)
    followers = data.followers
end

return {
    eventHandlers = {
        OMWMusicCombatTargetsChanged = targetsChanged,
        FDU_UpdateFollowerList = updateFollowerList,
    },
    interfaceName = 'FollowerDetectionUtil',
    interface = {
        getFollowerList = function() return followers end,
    },
}
