# Follower Detection Util (OpenMW)

## 2.0

- Deprecated the previous event convention, making it more intuitive and simple. Old events still work, so it's backwards compatible with mods built for 1.X versions of the library
- Bumped up the interface version
- Escort package is no longer affects follower status due to it breaking the logic (the package is not removed when the actor reaches its destination, making them your permanent followers) and its inclusion not making much sense in the first place (really, what did I think when I added it?)
- Added I.FollowerDetectionUtil.follows() shortcut function. Check the readme or Nexus description for details
- General optimization pass, but nothing significant
- Added more bugs to fix later

## 1.1.8

- Fixed mod not being able to reach settings on the first install

## 1.1.7

- Made settings apply without needing to reload scripts
- Removed leftover prints

## 1.1.6

- Fixed events being sent twice. I think?
- Fixed superleader not being set to nil if actor loses their leader
- Improved docs

## 1.1.5

- Performance improvements

## 1.1.4

- Fixed incorrect follower removal when the world is paused
- Unloaded followers are no longer removed from the follower list

## 1.1.3

### Fixes

- Fixed follower list not removing inactive followers

## 1.1.2

### Fixes

- Fixed lagspikes on follower list updates for saves with a lot of hours in them

## 1.1.1

### Changes

- Added mod version to the interface

## 1.1

### Changes

- Follower list now also stores followers who don't follow player
- All scripts now store full follower list in the save file
- Minor optimizations all around

### Fixes

- Super leader field now stores actors instead of their states (for consistency)

## 1.0.1

### Fixes

- Fixed error while parsing AI packages with no target

## 1.0

Initial release
