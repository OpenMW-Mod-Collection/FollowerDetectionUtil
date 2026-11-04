---@omw-context local|global
local M = {}

local stupidlyNamedSummons = {
    ["bonewalker_greater_summ"] = true,
}

---@param id string
---@return boolean
M.isSummon = function(id)
    return (
        stupidlyNamedSummons[id]
        or string.find(id, "_summon$")
        or string.find(id, "_s$")  -- Tamriel Data compat
    ) ~= nil
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

M.interfaceVersion = 6

return M
