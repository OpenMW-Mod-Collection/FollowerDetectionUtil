# Follower Detection Util (OpenMW)

Mod library for centralized and convenient follower tracking.

***If you're a player, this is just a dependency for other mods. It doesn't do anything on its own.***

## Idea

Each NPC and Creature is assigned a `State`:

- Leader - an actor that is being followed
- Super Leader - an actor which leader follows (used mostly for summons)
- Follows player - a flag which sets to True if either Leader or Super Leader is a player

## When the `State` is Being Updated

For each NPC and Creature:

- On being loaded
- On AI packet being added (by a Lua script, not the engine)
- On AI packet being removed
- On target change (Player script -> OMWMusicCombatTargetsChanged)

`State` for already loaded Actors might take and additional frame to update.  
Super Leader might take an additional frame to get its value set.

## Usage

`State` schema:

```lua
---@class State
---@field leader types.NPC|types.Creature|nil
---@field superLeader types.NPC|types.Creature|nil
---@field followsPlayer boolean
```

API is context-sensitive and always operates on the NPC or Creature whose script is calling it.

Available interface endpoints:

```lua
--- Returns the State of the calling actor.
--- Script scope: NPC, Creature
--- @return State
I.FollowerDetectionUtil.getState()

--- Returns State of each current follower.
--- Script scope: Global, NPC, Creature, Player
--- @return { followers: table<actorId, State> }
I.FollowerDetectionUtil.getFollowerList()
```

Interesting events:

```lua
--- Returns State of each current follower.
--- Script scope: NPC, Creature, Player
--- @return { followers: table<actorId, State> }
FDU_UpdateFollowerList
```

## Credits

**Sosnoviy Bor** - Author
