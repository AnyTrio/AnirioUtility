# Changelogs - Spatial Query

## [v1.1.0] Overlap params update + General spatial query | 2026/06/28

Updated `getWhitelistedInParts()` to use the new `IncludeInstances` property of `OverlapParams`.

Added the `worldRoot` parameter to `getWhitelistedInParts()`, default being `workspace`.

Added new `getPartsInParts()` method:
- Performs spatial query on one or more spatial parts.
- Similar api to [`GetPartsInPart()`](https://create.roblox.com/docs/reference/engine/classes/WorldRoot#GetPartsInPart) but for multiple parts.
- Uses a new internal method `getPartsInSinglePart()`.
- Efficient querying depending on the shape of the spatial parts.

Slightly cleaned up the module script.
