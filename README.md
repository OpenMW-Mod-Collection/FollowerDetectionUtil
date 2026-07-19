# Follower Detection Util (OpenMW)

Library for centralized and convenient follower tracking.

**_If you're a player, this is just a dependency for other mods. It doesn't do anything on its own._**

## Overview

_Or why you should use this utility._

Follower Detection Util (FDU) has two primary goals:

1. **Centralize follower detection.**  
   Follower status is calculated once and shared across all follower-related mods, instead of being re-evaluated independently by each one.
2. **Make follower tracking convenient.**  
   Instantly access follower state from almost any script scope (Global, Player, NPC, Creature), register handlers for follower state changes, and query relationships with minimal overhead.

## Idea

Each NPC and Creature is assigned a `State` containing:

- **Actor** - the actor this state belongs to
- **Leader** - the actor being followed
- **Super Leader** - the actor the leader follows (used mainly for summons)
- **Follows player** - `true` if either Leader or Super Leader is a player

There's also a `FollowerList` that is being shared between all actors, players and a global scripts. It is indexed by `actor.id` (not `actor.recordId`) and contains all the `States` which have a `Leader`.

Both `State` and `FollowerList` can be accessed with FDU interfaces.

## Usage

`State` schema:

```lua
---@class State
---@field actor GameObject
---@field leader GameObject|nil
---@field superLeader GameObject|nil
---@field followsPlayer boolean
```

Available interface endpoints:

```lua
---Returns the State of the calling actor.
---Script scope: NPC, Creature
---@return State
I.FollowerDetectionUtil.getState()

---Returns State of each current follower.
---Script scope: Global, NPC, Creature, Player
---@return table<actor.id, State>
I.FollowerDetectionUtil.getFollowerList()

---Shortcut for checking if the follower follows the actor
---Script scope: Gloabl, NPC, Creature, Player
---@param fState State
---@param potentialLeader GameObject
---@return boolean
I.FollowerDetectionUtil.follows(fState, potentialLeader)

---Returns version of the interface.
---Script scope: Global, NPC, Creature, Player
---@return number
I.FollowerDetectionUtil.version
```

Available events:

```lua
---Returns State of a single follower being updated.
---Sent on: follower state update
---Script scope: Global
---@return State
FDU_FollowerStateUpdated

---Returns States of all existing followers.
---Sent on: follower list being updated
---Script scope: Global, NPC, Creature, Player
---@return table<actor.id, State>
FDU_SyncFollowerList
```

## Credits

**Sosnoviy Bor** - Author
