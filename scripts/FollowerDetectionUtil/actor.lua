---@diagnostic disable: param-type-mismatch
local storage = require("openmw.storage")
local self = require("openmw.self")
local async = require("openmw.async")

local State = require("scripts.FollowerDetectionUtil.model.state")
local settingsCache = require("scripts.FollowerDetectionUtil.utils.settingsCache")
require("scripts.FollowerDetectionUtil.logic.ai")
require("scripts.FollowerDetectionUtil.utils.consts")

local settings = settingsCache.new(storage.globalSection("SettingsFollowerDetectionUtil_settings"), async)
local updateTime = math.random() * settings.checkFollowersEvery
local state = State:new(GetLeader())
local followers = {}

local function noLongerFollowing()
    state:setLeader(nil)
end

-- +-----------------+
-- | Engine handlers |
-- +-----------------+

local function onUpdate(dt)
    updateTime = updateTime + dt

    if updateTime < settings.checkFollowersEvery then return end

    if settings.checkFollowersEvery == 0 then
        updateTime = 0
    else
        while updateTime > settings.checkFollowersEvery do
            updateTime = updateTime - settings.checkFollowersEvery
        end
    end

    state:setLeader(
        not self.type.isDead(self) and self:isValid()
        and GetLeader()
        or nil
    )
end

-- +----------------+
-- | Event handlers |
-- +----------------+

local function startAIPackage(pkg)
    if (pkg.type == "Follow" or pkg.type == "Escort") and pkg.target:isValid() then
        state:setLeader(pkg.target)
    end
end

local function removeAIPackage(pkgType)
    if pkgType == "Follow" or pkgType == "Escort" then
        noLongerFollowing()
    end
end

local function updateFollowerList(data)
    followers = data.followers
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onInactive = noLongerFollowing,
    },
    eventHandlers = {
        Died = noLongerFollowing,
        StartAIPackage = startAIPackage,
        RemoveAIPackage = removeAIPackage,
        FDU_UpdateFollowerList = updateFollowerList,
    },
    interfaceName = 'FollowerDetectionUtil',
    interface = {
        version = ModVersion,
        getState = function() return state end,
        getFollowerList = function() return followers end,
    },
}
