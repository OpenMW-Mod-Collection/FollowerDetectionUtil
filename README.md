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
- **Leaders** - the whole follower chain
- **Followers** - the actors that follow this actor directly
- **Follows player** - `true` if the player is anywhere in the chain
- **Is summon** - `true` if the summon record id matches the FDU's summon naming rules

There's also a `FollowerList` that is being shared between all actors, players and the global script. It is indexed by `actor.id` (not `actor.recordId`) and contains the `States` of all actors that follow anyone.

Actor is no longer considered a follower if it:

- Dies
- Gets disabled
- Gets unloaded (invalid)

## Usage

### `State` Class

```lua
---@class State
---@field actor openmw.GObject
---@field leader openmw.GObject?         -- who the actor follows directly
---@field leaders openmw.GObject[]       -- the whole follower chain
---@field rootLeader openmw.GObject?     -- last actor of the chain, same as leaders[#leaders]
---@field depth integer                  -- #leaders. 0 - follows nobody, 1 - follows someone, 2 - follows someone's follower, etc
---@field followers openmw.GObject[]     -- actors that follow this actor directly
---@field isSummon boolean
---@field followsPlayer boolean          -- the player is anywhere in the chain
```

Theoretical example, `Player > Companion > Summon > Summon's summon`:

| **Actor**       | **Leader** | **Leaders**                   | **Followers**       | **Follows player** |
| --------------- | ---------- | ----------------------------- | ------------------- | ------------------ |
| Companion       | Player     | `{Player}`                    | `{Summon}`          | `true`             |
| Summon          | Companion  | `{Companion, Player}`         | `{Summon's summon}` | `true`             |
| Summon's summon | Summon     | `{Summon, Companion, Player}` | `{}`                | `true`             |

A `State` read from `getFollowerList()` is a snapshot, while the one from `getState()` is kept up to date automatically. `followers` and `leaders` hold actors, not states, so there are no circular references and the states can be sent as event data. Use `getFollowerList()[actor.id]` to get the state of one of them (if it follows the player).

`State.isSummon` supports summons from:

- Vanilla
- [Tamriel_Data](https://www.nexusmods.com/morrowind/mods/44537)

### Interfaces

```lua
---Returns the State of the calling actor.
---The returned State will be kept in sync too.
---Script scope: NPC, Creature
---@return State
I.FollowerDetectionUtil.getState()

---Returns State of each current follower.
---Script scope: Global, NPC, Creature, Player
---@return table<actor.id, State>
I.FollowerDetectionUtil.getFollowerList()

---Shortcut for checking if the follower follows the actor (even if indirectly).
---Script scope: Global, NPC, Creature, Player
---@param state State
---@param potentialLeader openmw.GObject
---@return boolean
I.FollowerDetectionUtil.follows(state, potentialLeader)

---Returns States of the followers of the actor, taken from the follower list.
---Script scope: Global, NPC, Creature, Player
---@param leader openmw.GObject
---@param recursive boolean? default: false
---@return State[]
I.FollowerDetectionUtil.getFollowersOf(leader, recursive)

---Shortcut for checking if the follower is summon
---Script scope: Global, NPC, Creature, Player
---@param recordId string
---@return boolean
I.FollowerDetectionUtil.isSummon(recordId)

---Returns version of the interface.
---Script scope: Global, NPC, Creature, Player
---@return number
I.FollowerDetectionUtil.version
```

### Events

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
