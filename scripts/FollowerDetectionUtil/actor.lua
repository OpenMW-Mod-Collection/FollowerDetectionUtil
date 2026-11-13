---@diagnostic disable: undefined-field
---@omw-context local
local storage = require("openmw.storage")
local self = require("openmw.self")
local async = require("openmw.async")
local I = require("openmw.interfaces")

local State = require("scripts.FollowerDetectionUtil.model.state")
local settingsCache = require("scripts.FollowerDetectionUtil.utils.settingsCache")
local common = require("scripts.FollowerDetectionUtil.utils.common")

local pendingLeader
local function leaderCollector(pkg)
    if pkg.type == "Follow" and pkg.target and pkg.target:isValid() then
        pendingLeader = pkg.target
        return
    end
end

local function getLeader()
    pendingLeader = nil
    I.AI.forEachPackage(leaderCollector)
    return pendingLeader
end

local settings = settingsCache.new(storage.globalSection("SettingsFollowerDetectionUtil_settings"), async)
local updateTime = math.random() * settings.checkFollowersEvery
local state = State:new(not self.type.isDead(self) and getLeader() or nil)
local followers = {}

local function noLongerFollowing()
    state:setLeader(nil)
end

-- +-----------------+
-- | Engine handlers |
-- +-----------------+

local function onInactive()
            noLongerFollowing()
    end

-- the script could have been kept while the actor was unloaded,
-- so what the global scripts knows about it may be outdated by now
local function onActive()
    if state.leader then
        state:updateFollowerList()
    end
end

local function onUpdate(dt)
    local interval = settings.checkFollowersEvery
    updateTime = updateTime + dt

    if updateTime < interval then return end
    updateTime = (interval == 0) and 0 or (updateTime % interval)

    state:setLeader(
        not self.type.isDead(self) and self:isValid()
        and getLeader()
        or nil
    )
end

-- +----------------+
-- | Event handlers |
-- +----------------+

local function startAIPackage(pkg)
    if pkg.type == "Follow" and pkg.target and pkg.target:isValid() then
        state:setLeader(pkg.target)
    end
end

local function removeAIPackage(pkgType)
    if pkgType == "Follow" then
        noLongerFollowing()
    end
end

local function syncFollowerList(data)
    followers = data
end

local function syncState(data)
    state:sync(data)
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onActive = onActive,
        onInactive = onInactive,
    },
    eventHandlers = {
        Died = noLongerFollowing,
        StartAIPackage = startAIPackage,
        RemoveAIPackage = removeAIPackage,
        FDU_SyncFollowerList = syncFollowerList,
        FDU_SyncState = syncState,
    },
    interfaceName = 'FollowerDetectionUtil',
    interface = {
        version = common.interfaceVersion,
        getState = function() return state end,
        getFollowerList = function() return followers end,
        getFollowersOf = function(leader, recursive)
            return common.getFollowersOf(followers, leader, recursive)
        end,
        follows = common.follows,
        isSummon = common.isSummon,
    },
}
