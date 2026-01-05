local followers = {}

---The best option we have for AI package updates
---@param data { actor: any, targets: table<any> }
local function targetsChanged(data)
    data.actor:sendEvent("FDU_ReInitState")
end

---@param data { followers: table<State> }
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
