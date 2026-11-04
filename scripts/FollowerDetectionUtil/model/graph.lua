local types = require "openmw.types"
---@omw-context local|global

---@class FollowerGraphOptions
---@field isSummon fun(recordId: string): boolean

---@class FollowerGraph
---@field private nodes table<string, {actor: openmw.GObject, leader: openmw.GObject}>
---@field private children table<string, table<string, openmw.GObject>>
---@field private sigs table<string, string>
---@field private depths table<string, integer>
---@field private isSummon fun(recordId: string): boolean
---@field private summons table<string, boolean>
local Graph = {}
Graph.__index = Graph

---@param opts FollowerGraphOptions
---@return FollowerGraph
function Graph.new(opts)
    return setmetatable({
        isSummon = opts.isSummon,
        nodes = {},    -- [actor.id] = { actor, leader }
        children = {}, -- [leader.id] = { [actor.id] = actor }
        sigs = {},     -- [actor.id] = signature of the last published state
        depths = {},   -- [actor.id] = depth of the last published state
        summons = {},  -- [actor.id] = cached isSummon result
    }, Graph)
end

---@param a openmw.GObject
---@param b openmw.GObject
local function byId(a, b)
    return a.id < b.id
end

-- +-------+
-- | Edges |
-- +-------+

---@param actor openmw.GObject
---@param leader openmw.GObject?
---@return boolean changed false if the actor already had exactly this leader
---@return openmw.GObject? previousLeader
function Graph:setLeader(actor, leader)
    local id = actor.id
    local node = self.nodes[id]
    local previous = node and node.leader

    -- following yourself is meaningless
    if leader and leader.id == id then
        leader = nil
    end

    local previousId = previous and previous.id
    local leaderId = leader and leader.id
    if previousId == leaderId then
        return false, previous
    end

    if previousId then
        local siblings = self.children[previousId]
        if siblings then
            siblings[id] = nil
            if next(siblings) == nil then
                self.children[previousId] = nil
            end
        end
    end

    if leader then
        self.nodes[id] = { actor = actor, leader = leader }
        local siblings = self.children[leaderId]
        if not siblings then
            siblings = {}
            ---@diagnostic disable-next-line: need-check-nil
            self.children[leaderId] = siblings
        end
        siblings[id] = actor
    else
        self.nodes[id] = nil
    end

    return true, previous
end

-- +----------------+
-- | Change scoping |
-- +----------------+

---@param actor openmw.GObject
---@param out table<string, openmw.GObject>
function Graph:collectDescendants(actor, out)
    local seen = { [actor.id] = true }
    local stack = { actor.id }
    while #stack > 0 do
        local id = table.remove(stack)
        local kids = self.children[id]
        if kids then
            for kidId, kid in pairs(kids) do
                if not seen[kidId] then
                    seen[kidId] = true
                    out[kidId] = kid
                    stack[#stack + 1] = kidId
                end
            end
        end
    end
end

---@param actor openmw.GObject
---@param leader openmw.GObject?
---@param previous openmw.GObject?
---@return table<string, openmw.GObject>
function Graph:affectedBy(actor, leader, previous)
    local seeds = { [actor.id] = actor }
    if leader then seeds[leader.id] = leader end
    if previous then seeds[previous.id] = previous end
    self:collectDescendants(actor, seeds)
    return seeds
end

-- +--------+
-- | States |
-- +--------+

---@param state table
---@return string
local function signature(state)
    local chain, kids = {}, {}
    for i, o in ipairs(state.leaders) do chain[i] = o.id end
    for i, o in ipairs(state.followers) do kids[i] = o.id end
    return table.concat(chain, ",") .. "|" .. table.concat(kids, ",")
end

---@param actor openmw.GObject
---@return table
function Graph:build(actor)
    local id = actor.id

    local leaders, seen = {}, { [id] = true }
    local node = self.nodes[id]
    local current = node and node.leader
    while current and not seen[current.id] do
        seen[current.id] = true
        leaders[#leaders + 1] = current
        local nextNode = self.nodes[current.id]
        current = nextNode and nextNode.leader
    end

    local followers = {}
    local kids = self.children[id]
    if kids then
        for _, kid in pairs(kids) do followers[#followers + 1] = kid end
        table.sort(followers, byId)
    end

    -- recordId can't be read from an object which doesn't exist anymore
    local summon = self.summons[id]
    if summon == nil then
        summon = self.isSummon(actor.recordId)
        self.summons[id] = summon
    end

    local root = leaders[#leaders]
    return {
        actor = actor,
        leader = leaders[1],
        leaders = leaders,
        rootLeader = root,
        depth = #leaders,
        followers = followers,
        isSummon = summon,
        followsPlayer = root and types.Player.objectIsInstance(root),
    }
end

---@param seeds table<string, openmw.GObject>
---@return table[] changed
---@return table<string, boolean> wasFollower [actor.id] = true if the actor was a follower before this refresh
function Graph:refresh(seeds)
    local changed, wasFollower = {}, {}

    for id, actor in pairs(seeds) do
        if not types.Player.objectIsInstance(actor) then
            local state = self:build(actor)
            local empty = state.depth == 0 and #state.followers == 0
            local sig = (not empty) and signature(state) or nil

            if sig ~= self.sigs[id] then
                wasFollower[id] = (self.depths[id] or 0) > 0
                self.sigs[id] = sig
                self.depths[id] = (not empty) and state.depth or nil
                changed[#changed + 1] = state
            end
        end
    end

    table.sort(changed, function(a, b)
        if a.depth ~= b.depth then return a.depth < b.depth end
        return a.actor.id < b.actor.id
    end)

    return changed, wasFollower
end

return Graph
