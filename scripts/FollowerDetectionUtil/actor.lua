local State = require("scripts.FollowerDetectionUtil.model.state")
require("scripts.FollowerDetectionUtil.logic.ai")

-- state
local state = State:new(GetLeader())
local followers = {}

---@param pkg { type: string, target: any }
local function startAIPackage(pkg)
    if pkg.type == "Follow" or pkg.type == "Escort" then
        state:setLeader(pkg.target)
    end
end

---@param pkgType string
local function removeAIPackage(pkgType)
    if pkgType == "Follow" or pkgType == "Escort" then
        state:setLeader(nil)
    end
end

local function reInitState()
    state:setLeader(GetLeader())
end

---@param data { followers: table<State> }
local function updateFollowerList(data)
    followers = data.followers
end

return {
    eventHandlers = {
        StartAIPackage = startAIPackage,
        RemoveAIPackage = removeAIPackage,
        FDU_ReInitState = reInitState,
        FDU_UpdateFollowerList = updateFollowerList,
    },
    interfaceName = 'FollowerDetectionUtil',
    interface = {
        getState = function() return state end,
        getFollowerList = function() return followers end,
    },
}
