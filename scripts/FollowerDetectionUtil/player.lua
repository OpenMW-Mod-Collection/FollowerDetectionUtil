---The best option we have for AI packet updates
---@param data table { actor = types.Actor, targets = targets }
local function OMWMusicCombatTargetsChanged(data)
    data.actor:sendEvent("reInitState")
end

return {
    eventHandlers = {
        OMWMusicCombatTargetsChanged = OMWMusicCombatTargetsChanged
    }
}