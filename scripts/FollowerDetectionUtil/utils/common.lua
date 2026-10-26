---@omw-context local|global
local M = {}

---@param id string
---@return boolean
M.isSummon = function(id)
    return (
        string.find(id, "_summon$")
        or id == "bonewalker_greater_summ"
        or string.find(id, "_s$")     -- Tamriel Data compat
    ) ~= nil
end

M.interfaceVersion = 5

return M
