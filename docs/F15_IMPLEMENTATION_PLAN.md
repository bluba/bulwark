# F15 implementation plan — curated supply caches

Status: first medical-cache slice implemented in source; Arma acceptance pending. This document preserves the implementation design and acceptance gates. See [current behavior and settings](SUPPLY_CACHES.md) for the delivered slice. No PBO has been built.

**Delivery revision (2026-10-30):** the user requested paradrops matching the support supply drop. The implemented delivery now supersedes ground-spawn/indoor-placement details below: open outdoor LZ, VTOL approach, parachute descent and blue smoke; stock and lifetime begin after safe landing. Aircraft/crew/chute assets are owned by the cache record and cancel with it. See [current delivery behavior](SUPPLY_CACHES.md#paradrop-delivery).

**Shop revision (2026-10-31):** the user replaced random drops and paradrop delivery with paid, normally placeable crates in a separate Supplies tab. Current behavior is [documented here](SUPPLY_CACHES.md). The former delivery/lifetime/once-per-wave rules below are historical and do not apply to purchased crates.

## Recommended first release

Add one **marked medical cache** outside the immediate defense perimeter. Players collect a small, finite stock through normal crate inventory. Keep ordinary random loot, the white bonus objective and enemy FOBs intact. The cache is optional and never prevents wave completion.

Medical supplies are useful regardless of the configured weapon faction. This is the lowest-complexity first family. Ammunition and engineering caches follow after the placement and lifecycle pass multiplayer testing; personalized refill, salvage delivery, new guards, bank rewards and a general objective framework are outside this release. F03 is not a prerequisite.

Proposed starting defaults, to be tuned in playtesting:

| Setting | Default | Behavior |
| --- | --- | --- |
| Enabled | `true` | Disable without affecting ordinary loot. |
| Spawn chance | `0.20` | One independent 20% roll per combat wave, including wave one; misses consume the wave's attempt. Replaces the original fixed-wave schedule at the user's request. |
| Concurrent caches | `1` | Includes placement in progress; no duplicate workers. |
| Preferred distance | `150–300 m` | Measured from a captured truck position. |
| Outdoor fallback distance | `100–150 m` | Smaller trip when preferred sites fail. |
| Lifetime | `180 s` | Survives the current combat/preparation transition, but never into the next combat wave. |
| Stock | `6 FirstAidKit + 1 Medikit` | Shared stock, fixed per team; no player-count or wave scaling. |
| Relocation cancellation | `75 m` | Cancel if the truck moves this far from the captured anchor. |

Six FAKs are intentionally below the mission's ten-FAK conversion threshold. Transferring them into existing stocks can still produce a Medikit at the normal cost; that is valid use of the current mechanic. Do not replenish stock after a player dies, reconnects or closes inventory.

## Source findings that determine the design

| Current source | Consequence for implementation |
| --- | --- |
| `loot/spawnLoot.sqf` uses building positions within 100 m of the truck and exits if none exist. | Use a separate bounded placement function with an outdoor fallback. An early return from ordinary loot must not suppress F15. |
| `missionLoop.sqf` starts ordinary loot before wave one; `fn_startWave.sqf` cleans and respawns it from wave two onward. | Schedule F15 once from the wave-start owner, independently of `spawnLoot.sqf`, after ordinary loot refresh. |
| `loot_fnc_cleanup` calls `loot_fnc_get`, which searches specified object classes around all players. | Choose an ordinary inventory crate outside those classes and give it an explicit F15 owner tag. Verify the exclusion; do not add it to this discovery helper. |
| `loot_fnc_deleteIfEmpty` only deletes `WeaponHolderSimulated_Scripted`. | It cannot own F15 cleanup. Detect emptiness on the server's tracked crate only. |
| `bulwark_fnc_waveActive` returns false throughout preparation. | Do not use it as the continuing-cache predicate: this cache deliberately remains usable during preparation. |
| Wave completion tracks hostile jobs, enemies and living FOB caches. | Do not register F15 in `BW_ACTIVE_FOBS`, `BW_SPAWN_JOBS` or hostile queues. |
| `bulwark/fakToMedKit.sqf` processes the truck and nearby `Box_NATO_Support_F` crates. | Choose a different validated crate class so cache contents are not rewritten while players loot it. |
| F12 publishes a fixed team-status array and maintains HUD/markers in an existing client tick. | Add a separate small supply snapshot instead of changing array positions consumed by current HUD/tests. |
| Loot whitelist mode 1 is exclusive; mode 2 augments ordinary loot. | Filter the medical profile against the existing item policy. An empty allowed profile means skip, not bypass the whitelist. |

## Placement and contents

### Bounded placement

1. Capture truck object, position, wave number and a unique instance ID. Reserve the singleton before starting asynchronous placement.
2. Build a finite list of nearby buildings with usable positions in the preferred annulus. Randomize and examine at most **24 candidate positions**; do not retry indefinitely or rescan the map each tick.
3. Reject positions outside map bounds, in water, outside the distance band, inside solid geometry or without enough room for the crate. Prefer ground-floor positions with a nearby outdoor approach. Do not assume every `buildingPos` is accessible.
4. If no building candidate passes, examine at most **12 outdoor candidates** in the fallback band, with land, slope and clearance checks. Treat a safe-position helper's return as a candidate to validate, including any default/failure return.
5. Recheck instance, wave, captured truck identity/position and cancellation before object creation and before publishing the marker. Initial publication requires active combat: a delayed deployment must not create a fresh cache after preparation has opened. Failed placement releases the reservation and records one reason; do not retry again that wave.

Geometric checks cannot prove a walkable route on arbitrary terrain. Test representative Altis town, industrial and coastal sites. Skip the cache when neither placement tier passes; do not place it in the water or at an unchecked world-origin fallback. Base loot continues according to its existing behavior, including its current no-building limitation.

### Fixed, validated stock

Use a candidate vanilla inventory crate such as `Box_NATO_Equip_F`, subject to a config/capacity and in-engine access check. If unavailable or unsuitable, skip with a diagnostic until a tested fallback class is configured. Do not substitute `Box_NATO_Support_F` or a weapon holder implicitly.

Clear every cargo category before adding the approved manifest with global cargo operations. Validate configured class existence, correct item category, positive integer quantities and hard quantity caps. Do not trust a classname/amount sent by a client.

Resolve the effective item policy once per deployment:

- Mode 0: medical profile minus `LOOT_BLACKLIST`.
- Mode 1: medical profile intersected with `LOOT_WHITELIST_ITEM`, then minus the blacklist.
- Mode 2: the same curated medical profile minus the blacklist; whitelisting does not add unrelated supplies to this family.

Drop unavailable/disallowed entries; publish only if at least one useful medical item remains. Keep validation separate from the general config-wide loot discovery. This release contains no ammunition, so it cannot issue incompatible magazines. A later ammo family needs explicit tested weapon/magazine profiles and a separate compatibility gate, including weapons whose magazines are inherited or supplied through magazine wells.

## Lifecycle, inventory and multiplayer ownership

Use a server-owned record, for example `BW_SUPPLY_CACHE`, with named fields for `id`, `wave`, `state`, `crate`, `anchorObject`, `anchorPosition`, `expiresAt`, `manifest` and `worker`. Keep a monotonically increasing serial and last attempted wave separately. Clients receive only display data.

States: `placing -> available -> terminal`. Terminal reasons: `empty`, `expired`, `destroyed`, `relocated`, `nextWave`, `extraction`, `missionEnded`, or `placementFailed`.

- Availability continues while the originating wave number still matches, the mission runs, extraction has not begun, the truck is the same object and remains within the relocation threshold, and the lifetime has not elapsed. `buildPhase` changing to true is allowed.
- At the next combat start, after its final preparation countdown and before incrementing `attkWave`, cancel the previous instance. Do not delete it just because `fn_endWave` opened preparation.
- A single lightweight server worker may check the **one tracked crate** each second. This is needed during preparation and long wave-start operations; do not add world scans or per-frame handlers.
- Depletion checks cover items, magazines, weapons, backpacks and nested containers. Player-deposited cargo counts as remaining stock but does not extend the deadline. Expiry deletes any cargo still inside; label the cache as temporary and show its remaining lifetime.
- Use ordinary shared inventory rather than a custom reward action. There is no claim RPC, points award, personal grant or refill. Two players compete for the same finite cargo using the engine's inventory behavior; concurrency must be verified on a dedicated server.
- Keep the crate server-owned, stationary and excluded from mission pickup/build/salvage actions. Test inventory in place and vehicle loading; if vanilla/mod logistics can load it, use the available supported restriction or explicitly cancel it when moved from its site.
- Terminal cleanup is idempotent and instance-bound. Clear public availability and remove the marker, then delete the owned object, clear the record and release the singleton. A delayed worker from instance A must never clear instance B.
- Explicit next-wave and mission-ending cleanup must work even if the worker failed or the object was externally deleted. Extraction also cancels placement before any late crate can appear.

No new remotely callable gameplay mutation is required for this slice. Broad existing remote-execution settings remain an independent hardening concern; server-created stock does not establish resistance to arbitrary malicious clients.

## Map, HUD and JIP

Publish a separate `BW_SUPPLY_STATUS` snapshot: `[instanceId, crate, position, expiresAt, originatingWave]`, or `[]` when absent. Use `serverTime` consistently for the published expiry.

Extend `bulwark_fnc_tacticalClient` to maintain one local medical-cache marker and a supply line on the existing board. Labels must include the cache type and remaining time, with English/Polish entries in `stringtable.xml`. Show the temporary-stock warning at the site or through the inventory interaction guidance. Keep global marker creation out of client callbacks.

Add the snapshot and a coarse remaining-seconds value to the client's existing HUD change key; otherwise a separate snapshot would not trigger a refresh. Recover the marker and board on JIP/HUD recreation, and hide them immediately on locally observed destruction or expiry even if a server update is delayed. No remote-execution JIP action queue is needed. Retain the current mission's public snapshot/side-rendering policy; do not claim confidential transport.

## Implementation work packages

Deliver in this order. Each step should leave a reviewable change; names below are proposed APIs, not existing functions.

| Step | Work / proposed files | Completion gate |
| --- | --- | --- |
| 1. Config and manifest | `editMe.sqf`; `loot/functions/fn_supplyManifest.sqf`; register in `loot/Functions.hpp` | Validate defaults, modes 0/1/2, missing classes, empty lists and quantity caps without spawning. |
| 2. Placement | `loot/functions/fn_findSupplySite.sqf` | Finite candidate budgets; test preferred/fallback/skip outcomes and cancellation. |
| 3. Lifecycle | `fn_startSupplyCache.sqf`, `fn_watchSupplyCache.sqf`, `fn_endSupplyCache.sqf` under `loot/functions`; registry entries | One instance, cargo created once, bounded worker, idempotent cleanup, no stale-instance mutation. |
| 4. Wave integration | Initialize in `missionLoop.sqf`; cancel prior instance before the next wave increment in `fn_startWave.sqf`; schedule eligible deployment after ordinary loot refresh; clean before ending the mission | Optional cache never blocks combat completion; ordinary loot still refreshes; preparation/ready-vote behavior remains valid. |
| 5. Team UI | `bulwark/functions/fn_tacticalClient.sqf`, `score/functions/fn_updateHud.sqf`, `stringtable.xml` | One marker, readable countdown, JIP recovery and complete cleanup. Preserve F12's existing team snapshot shape. |
| 6. Acceptance and docs | New `tests/supplyCache.sqf`; update `DEVELOPMENT.md`, backlog, handoff, feature guide and fixes after implementation | Static checks plus recorded hosted/dedicated results; accurately label any checks not run. |

Keep `loot/spawnLoot.sqf` and `loot_fnc_get` behavior unchanged unless a targeted integration test demonstrates a required exclusion. Share the small placement/manifest helpers with F03 later; do not introduce the whole objective catalogue now.

## Tests and acceptance

### Engine regression harness

Use an isolated idle server with the normal mission loop stopped. Save/restore globals, create and remove temporary objects, and report failures to RPT. Exercise the actual manifest/lifecycle functions rather than duplicating their decisions in a test model.

- Allowed stock, strict whitelist, blacklist priority, missing item/crate classes, partial/empty profiles and bad quantities.
- Wave eligibility, disabled feature, two concurrent deployment attempts, one failed attempt per wave and at most one published crate.
- Empty building list, rejected building positions, outdoor fallback, exhausted candidate budget and cancellation during placement.
- Fixed cargo without default crate contents; repeated start or inventory-close events cannot replenish it.
- Empty/destroyed/externally deleted crate; expiry; repeated cleanup; stale instance cleanup; relocation and truck replacement.
- Availability during preparation; cancellation on the next combat wave, extraction and every mission ending.
- Ordinary loot cleanup leaves the F15 crate intact; F15 cleanup leaves ordinary loot and other objective objects intact.

### Hosted and dedicated sessions

1. Two players take the final item simultaneously; total acquired stock cannot exceed the manifest. Reconnect, respawn and reopen inventory: no refill.
2. Join while the cache exists, after depletion and after expiry. Verify exactly one correct marker/board entry and no stale actions or labels.
3. Clear combat quickly, use F01 to skip preparation, and collect near the next-wave/expiry boundary. Verify cleanup once and no next-wave orphan.
4. Move/carry/replace the truck and attempt to load/move the cache. Confirm the chosen relocation/transport rules.
5. Test town, industrial, hillside and coastal anchors, including a site with no usable buildings. Manually verify access and usable inventory interaction.
6. Check English/Polish labels, supported UI scales and maps. Run with the mission's real mods and both configured faction modes; supplies remain useful without ammunition assumptions.
7. Repeat eligible deployments across several waves, inspect RPT and object/worker counts, and confirm no accumulation or additional hostile-capacity jobs.

Acceptance requires usable finite supplies, bounded placement with a safe skip, no duplicate generation, correct cleanup/JIP and unchanged wave completion. Static checks verify SQF/config delimiters, function registration, paths, XML and translation placeholders; they do not establish gameplay acceptance. Do not package a PBO under the current user instruction.

## Cost and later extensions

This is a **medium implementation** with low-to-medium runtime complexity. The main effort is reliable placement, multiplayer inventory behavior and cleanup around phase changes. The fixed stock and single instance keep balance and performance reviewable. No calendar estimate is implied before the in-engine placement checks.

After the medical family passes acceptance, add explicit curated ammunition profiles, then an engineering family backed by actual services. Distance-based reward tiers, player-count scaling, delivery/salvage rewards and independent guards each need a separate balance/lifecycle decision. Preserve this release's small scope when recording cost/benefit; it does not implement all broader F15 ideas.
