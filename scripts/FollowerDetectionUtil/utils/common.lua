---@diagnostic disable: param-type-mismatch
---@omw-context local|global
local M = {}

local stupidlyNamedSummons = {
    ["bonewalker_greater_summ"] = true,
}

---@type table<integer, fun(actor: openmw.GObject): boolean>
local summonFilters = {}

local registeredSummonFilters = {}

---@param filter fun(actor: openmw.GObject): boolean
function M.registerSummonFilter(filter)
    assert(type(filter) == "function", "summon filter must be a function")
    if registeredSummonFilters[filter] then
        return
    end
    registeredSummonFilters[filter] = true
    summonFilters[#summonFilters + 1] = filter
end

---The record ID overload is deprecated; pass an actor object instead.
---@overload fun(recordId: string): boolean
---@param actor openmw.GObject
---@return boolean
M.isSummon = function(actor)
    local legacyMode = type(actor) == "string"
    local id = legacyMode and actor or actor.recordId

    if
        stupidlyNamedSummons[id]
        or string.find(id, "_summon$")
        or string.find(id, "_s$") -- Tamriel Data compat
    then
        return true
    end

    if legacyMode then
        return false
    end

    for _, filter in ipairs(summonFilters) do
        if filter(actor) then
            return true
        end
    end
    return false
end

---@param state State
---@param potentialLeader openmw.GObject
---@return boolean
M.follows = function(state, potentialLeader)
    if state.leaders then
        for i = 1, state.depth do
            if state.leaders[i].id == potentialLeader.id then
                return true
            end
        end
        return false
    end
    return state.leader ~= nil and state.leader.id == potentialLeader.id
end

---@param list table<string, State>
---@param leader openmw.GObject
---@param recursive boolean? include followers of followers
---@return State[]
M.getFollowersOf = function(list, leader, recursive)
    local id = leader.id
    local result = {}
    for _, state in pairs(list) do
        if recursive then
            if M.follows(state, leader) then
                result[#result + 1] = state
            end
        elseif state.leader and state.leader.id == id then
            result[#result + 1] = state
        end
    end
    return result
end

M.interfaceVersion = 7

return M
