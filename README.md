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
---@field leaders openmw.GObject[]       -- the whole leader chain
---@field rootLeader openmw.GObject?     -- last actor of the chain, same as leaders[#leaders]
---@field depth integer                  -- #leaders. 0 - follows nobody, 1 - follows someone, 2 - follows someone's follower, etc
---@field followers openmw.GObject[]     -- actors that follow this actor directly.  For the full follower chain, use I.FollowerDetectionUtil.getFollowersOf()
---@field isSummon boolean
---@field followsPlayer boolean          -- the player is anywhere in the chain
```

Theoretical example, `Player > Companion > Summon > Summon's summon`:

| **Actor**       | **Leader** | **Leaders**                 | **Followers**     | **Follows player** |
| --------------- | ---------- | --------------------------- | ----------------- | ------------------ |
| Companion       | Player     | {Player}                    | {Summon}          | true               |
| Summon          | Companion  | {Companion, Player}         | {Summon's summon} | true               |
| Summon's summon | Summon     | {Summon, Companion, Player} | {}                | true               |

`A State read` from `getFollowerList()` is a snapshot, while the one from `getState()` is kept up to date automatically.

Tables `followers` and `leaders` hold actors, not states. Use `getFollowerList()[actor.id]` to get the state of one of them.

`State.isSummon` and `isSummon(recordId)` support summons from:

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

---Returns States of the followers of the actor.
---Script scope: Global, NPC, Creature, Player
---@param leader openmw.GObject
---@param recursive boolean? default: false     -- If false, will return only the direct followers. If true, will return the whole follower chain
---@return State[]
I.FollowerDetectionUtil.getFollowersOf(leader, recursive)

---Shortcut for checking if the follower is summon
---Script scope: Global, NPC, Creature, Player
---The record ID overload is deprecated; pass an NPC or Creature object instead.
---@overload fun(recordId: string): boolean
---@param actor openmw.GObject
---@return boolean
I.FollowerDetectionUtil.isSummon(actor)

---Registers an additional summon-matching predicate.
---Made for cases when you make a mod that adds summon-like followers
---(those which die or get disabled by themselves)
---Script scope: Global, NPC, Creature, Player
---@param filter fun(actor: openmw.GObject): boolean
I.FollowerDetectionUtil.registerSummonFilter(filter)

---Returns version of the interface.
---Script scope: Global, NPC, Creature, Player
---@return number
I.FollowerDetectionUtil.version
```

#### Why should I bother with `I.FollowerDetectionUtil.registerSummonFilter()`?

This function lets mods recognize summon-like followers without requiring FDU or other mods to hardcode each mod’s summon IDs. For example, [BFF](https://www.nexusmods.com/morrowind/mods/59384)’s Immortality script can ignore actors that FDU identifies as summons. Rather than having BFF’s developer add new summon IDs reactively, summon-mod authors can register a filter for their actors.

Passing a record ID to `I.FollowerDetectionUtil.isSummon()` remains supported for built-in naming rules (vanilla and TD summons), but registered filters are not run for string inputs.

Example how it may be used:

```lua
local I = require("openmw.interfaces")

I.FollowerDetectionUtil.registerSummonFilter(function(actor)
    return string.find(actor.recordId, "^my_mod_summon_") ~= nil
end)
```

Register filters during script initialization for all 4 contexts: Global, NPC, Creature, Player. A filter may be called repeatedly, so keep it side-effect-free and do not throw errors. The function is kept for the lifetime of that script instance and is not persisted in save data.

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
