---@omw-context player
local common = require("scripts.FollowerDetectionUtil.utils.common")

local followers = {}

local function syncFollowerList(data)
    followers = data
end

---@param filter fun(actor: openmw.GObject): boolean
local function registerSummonFilter(filter)
    common.registerSummonFilter(filter)
end

return {
    eventHandlers = {
        FDU_SyncFollowerList = syncFollowerList,
    },
    interfaceName = "FollowerDetectionUtil",
    interface = {
        version = common.interfaceVersion,
        getFollowerList = function()
            return followers
        end,
        getFollowersOf = function(leader, recursive)
            return common.getFollowersOf(followers, leader, recursive)
        end,
        follows = common.follows,
        isSummon = common.isSummon,
        registerSummonFilter = registerSummonFilter,
    },
}
