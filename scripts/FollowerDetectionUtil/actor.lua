require("scripts.FollowerDetectionUtil.state")

-- state
local state = InitState()

---@param pkg table { type = string, target = types.Actor }
local function startAIPackage(pkg)
    if pkg.type == "Follow" then
        state:setLeader(pkg.type)
        state:checkSuperLeader()
    end
end

---@param pkgType string
local function removeAIPackage(pkgType)
    if pkgType == "Follow" or pkgType == "Escort" then
        state:setLeader(nil)
    end
end

-- Happens in the summoner's script
---@param data table { sender = types.Actor }
local function checkSummonersLeader(data)
    data.sender:sendEvent("Summon_SetLeader", { superLeader = state.leader })
end

---@param data table { superLeader = types.Actor|nil }
local function setSuperLeader(data)
    state:setSuperLeader(data.superLeader)
end

return {
    eventHandlers = {
        StartAIPackage = startAIPackage,
        RemoveAIPackage = removeAIPackage,
        -- custom events
        Summon_CheckSummonersLeader = checkSummonersLeader,
        Summon_SetLeader = setSuperLeader,
    },
    interfaceName = 'FollowerDetectionUtil',
    interface = {
        getState = function() return state end,
    },
}
