local I = require('openmw.interfaces')

---@return unknown -- openmw.types.Actor|nil
function GetLeader()
    local leader
    I.AI.forEachPackage(function(pkg)
        if pkg.type == "Follow" then
            leader = pkg.target
            return
        end
    end)
    return leader
end