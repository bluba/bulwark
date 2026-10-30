# F15 extension plan — engineering supply cache

Status: implemented in source; Arma acceptance pending. This document preserves the design and acceptance gates. See [current behavior and configuration](SUPPLY_CACHES.md). No PBO has been built.

**Delivery revision (2026-10-30):** the user requested paradrops matching the support supply drop. The implemented delivery now supersedes ground-spawn/indoor-placement details below: open outdoor LZ, VTOL approach, parachute descent and blue smoke; stock and lifetime begin after safe landing. Aircraft/crew/chute assets are owned by the cache record and cancel with it. See [current delivery behavior](SUPPLY_CACHES.md#paradrop-delivery).

## Gameplay proposal

Add a marked engineering cache with a small random mix of AP/AT mines, a few fragmentation grenades, smoke and engineering tools. Players collect finite cargo through ordinary shared inventory. Reuse the medical cache's placement, 180-second lifetime, preparation survival, relocation cancellation and next-combat cleanup. No new guards, claim rewards, automatic repairs or refill action.

**Spawn policy:** preserve the medical cache's independent 20% roll per combat wave, including wave one. Add a separate 20% engineering roll. Allow at most one cache of each family: **two total**, including placement reservations. Consume each family's roll once per wave, including misses and failed placements. One family's failure must not cancel the other or produce a replacement family.

Before placement/configuration failures, independent rolls give 64% neither, 16% medical only, 16% engineering only and 4% both. This deliberately increases access to optional supplies without reducing the existing medical chance. Consecutive successes and long gaps remain possible. Do not introduce a fixed wave interval or escalating chance.

## Recommended contents

Draw once on the server per successful engineering spawn roll, after filtering each candidate pool against configuration and loot policy. Counts are inclusive uniform integer ranges. For a multi-unit category, select each unit's class independently and aggregate duplicate classes into one cargo entry. Do not reroll when inventory opens or a player reconnects.

| Category | Quantity | Curated default pool | Purpose |
| --- | --- | --- | --- |
| AP mines | **1–2 total** | `APERSMine_Range_Mag`, `APERSBoundingMine_Range_Mag`, `APERSTripMine_Wire_Mag` | Prepare infantry approaches. |
| AT mines | **1–2 total** | `ATMine_Range_Mag`, `SLAMDirectionalMine_Wire_Mag` | Prepare vehicle approaches. |
| Fragmentation grenades | **1–3 total** | `HandGrenade`, `MiniGrenade` | Clear close threats and buildings. |
| Screening smoke | **2 total** | `SmokeShell` | Cover collection, recovery and repositioning. |
| Mine detector | **1** | `MineDetector` | Find explosives using the existing game/mod mechanics. |
| Toolkit | **1** | `ToolKit` | Existing repair/engineering interactions where permitted. |

Hard caps apply to **category totals**, not independently to every class: at most four mines, three fragmentation grenades, two smoke grenades, one detector and one toolkit. No wave/player-count scaling. The initial family has no rifle ammunition, rockets, explosive satchels, mine dispensers, IEDs, backpacks, UAVs or construction objects.

An optional later addition is a single `DemoCharge_Remote_Mag` with a 25% content roll, disabled by default. It would need its own one-charge cap, config/capacity tests and a successful native detonation check. Keep it out of the first implementation so the initial explosive budget remains easy to assess. The current mission blacklists Claymores and satchels; retain that policy rather than using them as substitutions.

The default explosive pool names are drawn from Bohemia's [weapon/Put magazine definitions](https://community.bistudio.com/wiki/Arma_3%3A_CfgWeapons_Weapons). Actual loaded config, class category, inventory mass and usable actions must still be validated in the mission's mod set. Native mine placement, mine detection and smoke are documented in the [advanced weapons field manual](https://community.bistudio.com/wiki/Arma_3%3A_Field_Manual_-_Weapons_Advanced); use those existing mechanics as the baseline.

## Stock policy and usefulness gates

Mines, grenades and smoke are **magazine cargo** from `CfgMagazines`; toolkit and detector are **item cargo** from `CfgWeapons`. The pre-extension medical manifest and watcher assumed every entry was item cargo. Both now use tagged item/magazine entries; the medical-only `BW_SUPPLY_STOCK` still does not accept explosives.

Resolve policy before drawing contents:

1. Restrict candidates to explicit engineering-category pools. Validate class strings, config existence, positive integer quantities and category caps. Exclude noninventory/vehicle-ammunition entries; do not classify by translated display-name substrings.
2. Apply `LOOT_BLACKLIST` to every candidate, regardless of whitelist mode.
3. In mode 1, items must also appear in `LOOT_WHITELIST_ITEM`; all magazine categories must also appear in `LOOT_WHITELIST_EXPLOSIVE`. This includes smoke so it cannot bypass strict policy.
4. In modes 0 and 2, keep the curated engineering pools minus the blacklist. Existing broad mod loot discovery does not enlarge these pools.
5. An empty category contributes nothing and transfers no budget to another category. Do not replace forbidden AT mines with extra AP mines, extra grenades or medical cargo.
6. Require at least one AP or AT mine after filtering for an engineering deployment. If both mine categories are unavailable, skip the engineering cache and log the reason once. A restricted loadout can therefore intentionally disable this family without disabling medical supplies.
7. Resolve the entire manifest once, calculate combined item/magazine mass and validate the crate's capacity before creation. Oversized or malformed profiles fail closed, without partial publication or repeated rolls.

Default supplies should be useful to the current playable units. The source contains no explicit script granting all players engineering/explosive-specialist traits. The toolkit must not be described as granting unrestricted repairs or new F04 repair mechanics. Verify native tool and detector usability with actual playable classes and mods. If the toolkit provides no available interaction, omit it from that deployment profile rather than granting a role or adding a repair service silently.

The custom `Disarm Explosive` action in `onPlayerRespawn.sqf` deletes the object before reading its class and scans the entire magazine config. `Disarm Mine` deletes a mine without returning stock. Neither establishes reliable, server-validated salvage. Do not rely on these actions for cache value or extend them as part of this supply change. Any repair to recovery needs separate caller/ownership, class and duplicate-reward checks.

## Reuse the lifecycle, separate family state

Keep one shared implementation for placement, cargo publication, monitoring and cleanup. Add a validated family parameter (`medical` by default, or `engineering`) to the lifecycle APIs. Preserve existing medical defaults and namespace keys so its current behavior is not silently rebalanced.

Suggested server changes:

- A small `loot_fnc_supplyFamily` definition resolves only supported family IDs into config, record, last-attempt, result and snapshot keys. Reject unknown family IDs before mutation; never construct arbitrary namespace keys from client input.
- Medical retains `BW_SUPPLY_CACHE`, `BW_SUPPLY_LAST_ATTEMPT`, `BW_SUPPLY_LAST_RESULT` and `BW_SUPPLY_STATUS`. Engineering uses corresponding `BW_ENGINEERING_*` keys. Reuse a global monotonic `BW_SUPPLY_SERIAL` for unique instance IDs across both families.
- `startSupplyCache` accepts `[wave, family]`, atomically consumes that family's roll and reserves that family's singleton. `watchSupplyCache` accepts `[id, family]`; `endSupplyCache` accepts `[id, reason, family]`. Existing calls without family still mean medical.
- Keep the captured family in the record/worker. Cleanup must match both family and instance ID. A terminating engineering worker cannot clear a medical snapshot, stop the other worker or release the other reservation.
- Initialize both records/snapshots and last-attempt fields in `missionLoop.sqf`. At the existing deployment hook, attempt medical then engineering once. At next combat and mission endings, explicitly clean both families.
- Keep both families out of `BW_ACTIVE_FOBS`, `BW_SPAWN_JOBS` and hostile queues. At most two workers monitor their own objects once per second; no world-scanning or per-frame manager is needed.

Do not copy the whole medical lifecycle into separate engineering scripts. Keep family-specific content selection in a dedicated `fn_engineeringManifest.sqf` helper, and centralize shared lifecycle decisions.

### Mixed cargo representation

Normalize manifests to tagged entries, for example:

```sqf
[
    ["item", "ToolKit", 1],
    ["item", "MineDetector", 1],
    ["magazine", "APERSMine_Range_Mag", 2],
    ["magazine", "ATMine_Range_Mag", 1],
    ["magazine", "HandGrenade", 2],
    ["magazine", "SmokeShell", 2]
]
```

Adapt the medical helper to emit `item` entries while retaining its configured six/one stock and whitelist rules. Search callers and update its tests together; this is an internal format change, not a reason to change medical quantities.

The watcher clears every cargo category, then dispatches only supported tags to `addItemCargoGlobal` or `addMagazineCargoGlobal`. Item mass comes from the item's inventory config; magazine mass comes from `CfgMagazines`. Aggregate class/tag pairs and enforce category/overall limits before checking capacity. Unknown tags or a class in the wrong config root must not reach cargo commands.

### Prevent overlapping placements

Each family retains the existing 24-building/12-outdoor candidate budgets and distance bands. Add a **20-metre separation** from the other family's available or reserved site. Do not use one family as the other's placement anchor.

Expose exclusions to the placement helper, and recheck/reserve the chosen site atomically before publication. Two workers may choose the same site before either publishes; the final separation check must catch this race. If there is no remaining valid candidate within the original bounded budget, skip that family for the wave. Do not start another unlimited placement or chance loop.

## Cleanup semantics for collected explosives

The temporary crate and cargo still inside it follow the medical cache's existing cleanup rules. Supplies already taken by players are theirs. Mines placed from those supplies and grenades already thrown are **not owned by the cache lifecycle**; expiry must not delete them or refund them. Do not add an automatic demining sweep as part of this feature.

Friendly mine/explosion behavior must be tested with `TEAM_DAMAGE` both on and off. The current protection depends on damage-source/instigator attribution; do not assume mines are harmless to teammates when that setting is off. Preserve native/team-visible mine information and do not reveal unspotted hostile mines through the cache marker or board.

Repeated engineering successes can leave mines and carried explosives across waves. Start with the small caps above and inspect long-session mine counts and gameplay. A deployed-mine limit or end-of-wave sweep would be a separate rule requiring explicit ownership/lifecycle design.

## Map, board and configuration

Keep medical snapshot `[id, crate, position, expiresAt, wave]` unchanged. Publish the same shape separately as `BW_ENGINEERING_STATUS`. Extend the existing client tick to iterate the two known sources and maintain one marker per family, with distinct text and a restrained color difference. The board shows both lines/countdowns when both exist; labels must identify type without relying on color.

Use **Engineering cache / Skład inżynieryjny** and reuse the temporary-stock warning. Include both snapshots and expiry values in the HUD change key. Warning deduplication uses the unique instance ID; seeing one family must not suppress the other family's warning. JIP, destruction, expiry and family-specific cleanup must remove/recover the correct marker. Do not introduce a new JIP action queue or change F12's team-status array.

Proposed configuration:

| Setting | Default / policy |
| --- | --- |
| `BW_ENGINEERING_ENABLED` | `true` |
| `BW_ENGINEERING_CHANCE` | `0.20`; finite 0–1, independent of medical |
| `BW_ENGINEERING_CLASS` | Same validated inventory crate as medical by default |
| Engineering content pools/ranges | Explicit entries from the contents table; quantity/category hard caps remain authoritative |
| Lifetime and relocation | Inherit current medical settings: 180 seconds and 75 metres by default |
| Placement and motion cancellation | Same bands/checks and two-metre crate-motion threshold as medical; plus 20-metre cross-family separation |

Keep existing `BW_SUPPLY_CHANCE = 0.20` untouched. Changing one family's chance, disabling it or exhausting its allowed stock must not alter the other family's chance or manifest.

## Implementation sequence

| Step | Files / work | Completion gate |
| --- | --- | --- |
| 1. Definitions and mixed manifests | `editMe.sqf`; new family-definition and engineering-manifest helpers; `loot/Functions.hpp`; normalize `fn_supplyManifest.sqf` | Correct category roots/policies; bounded random contents; medical stock preserved; combined capacity resolved. |
| 2. Shared lifecycle parameterization | Existing start/watch/end supply functions | Unique IDs, per-family roll/singleton/state, no duplicated lifecycle and no cleanup cross-talk. |
| 3. Placement and wave integration | `fn_findSupplySite.sqf`, `fn_startWave.sqf`, `missionLoop.sqf` | Independent rolls, two-instance cap, separation under concurrent placement, both families cleaned at boundaries. |
| 4. Team display | `fn_tacticalClient.sqf`, `fn_updateHud.sqf`, `stringtable.xml` | Two correct markers/lines, English/Polish labels, JIP and independent expiry. |
| 5. Regression and docs | Update `tests/supplyCache.sqf`; add engineering content/concurrency coverage; update current guides/backlog/handoff after implementation | Existing medical cases still pass; actual mixed cargo and isolation verified; unrun checks labelled accurately. |

Expected cost: **medium**, mostly from removing the current single-family assumptions and testing mixed cargo/concurrency. New content selection alone is small; two-family lifecycle and UI support are required to preserve the existing medical chance.

## Acceptance tests

### Server/editor harness

- Assert exact unchanged medical stock after manifest normalization.
- Set each family's chance to 0 or 1 independently. Check all four combinations; no reroll after a miss or failed placement; no duplicate publication. Invalid/disabled engineering settings cannot consume or cancel a medical attempt.
- Generate repeated engineering manifests: AP/AT counts and selected classes remain within filtered pools, category caps apply after aggregation, and no excluded item appears. Empty pools terminate without retries; both mine pools empty skips engineering.
- Test strict item/explosive whitelists independently, blacklist priority, missing config classes, wrong cargo roots/tags, invalid quantities and capacity failure.
- Inspect the real crate: items are item cargo; mines/grenades/smoke are magazine cargo; no default contents or live placed explosives are spawned during cache creation.
- Publish both families, clean one twice and send stale cleanup IDs. The other crate, worker and snapshot must survive. Exercise preparation, next wave, extraction, truck relocation and mission ending with both workers active or placing.
- Force matching/nearby site candidates and exhausted fallback budgets. Check separation and bounded failure without overlapping objects or double reservations.
- Verify depletion checks include remaining magazines: taking only the tools must not remove a crate still containing mines.

### Hosted/dedicated sessions

1. Two players collect the last mine/grenade concurrently: no duplicated generated stock or refill on reopen/respawn/reconnect.
2. JIP while both exist; expire/destroy/move one. Only its marker and board line disappear, and both warnings can appear once.
3. Confirm mine placement, detector operation, native toolkit interactions and grenade selection with actual playable classes, both faction modes and the deployed mods. Do not treat successful item creation as proof of usable engineering mechanics.
4. Place a collected mine, then expire/delete its crate. The mine and items already carried remain; uncollected cargo disappears. Check normal side mine information and friendly damage behavior.
5. Validate two accessible separated sites in town, industrial, hillside and coastal situations; verify neither crate is removed by ordinary loot cleanup or enters construction pickup/sell/move actions.
6. Run repeated waves, including consecutive engineering successes. Inspect mine accumulation, server/RPT errors, at most two cache objects/workers and explosive impact on defense difficulty.

Run static SQF/config/stringtable/reference checks before engine testing. The current environment has no available Arma/SQF runtime; this document records proposed tests, not passed gameplay results. Preserve the existing no-PBO instruction.
