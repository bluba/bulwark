# F15 — finite medical and engineering supply caches

Both cache families are implemented in source. Arma acceptance is pending. The [medical plan](F15_IMPLEMENTATION_PLAN.md) and [engineering plan](ENGINEERING_CACHE_PLAN.md) preserve their design and multiplayer gates.

## Paradrop delivery

Both families now arrive like the active Supply Drop support: a `B_T_VTOL_01_vehicle_F` approaches at about 200 metres, releases the empty cache on a `B_Parachute_02_F`, and blue smoke marks a successful landing. Contents and the independent 20% rolls are unchanged. The map/board show inbound and descending stages before the landed stock countdown.

Aircraft transit is bounded to 180 seconds and descent to 120 seconds by default. Stock is added only after safe landing; the full 180-second cache lifetime starts then. A lost aircraft/chute, failed arrival, unsafe landing or excessive drift cancels that attempt without a ground-spawn/teleport fallback or reroll. Pending deliveries cancel when combat ends, extraction begins, the truck relocates/is replaced, or the mission ends. Already-landed crates still survive preparation.

The owning family record tracks aircraft, crew, group, parachute, crate and smoke. Cancellation removes all its registered assets before terminating its worker. Success removes the flight/chute assets at landing and retains the crate/smoke until normal cache cleanup. The existing shared aircraft-wait helper gained an optional cancellation predicate; old support/hostile callers retain their defaults.

## Spawn policy and lifecycle

Each combat wave, including wave one, independently rolls **20% medical** and **20% engineering**. Each family gets one attempt per wave: misses, invalid stock and placement failures cannot reroll or fall back to the other family. Medical probability and quantities remain unchanged. Consecutive successes or long gaps are possible. A successful roll still needs valid cargo and a usable site.

At most one of each family exists, including placement reservations: **two caches total**. They must be at least **20 metres apart**. Normal shared inventory supplies the stock; there is no claim reward, personal grant, refill, bank income or extra garrison. Neither cache blocks wave completion or uses hostile jobs/capacity.

Landed caches survive preparation, with a **180-second** post-landing lifetime continuing across the phase transition. The next combat transition explicitly cleans both after the warning countdown and before incrementing the wave. Depletion, destruction/external deletion, expiry, extraction, mission completion, truck replacement or movement at least **75 metres** from its captured position also cancel a cache. Moving a crate more than two metres, attaching it or loading it into vehicle cargo cancels that crate.

Only the owned crate and cargo still inside are deleted. Depositing items does not extend expiry; do not use a temporary cache as storage. Player-carried supplies, mines already placed and grenades already thrown remain. There is no automatic demining sweep. The nearby-player warning explains the temporary stock; map/HUD labels show time remaining.

## Medical contents and settings

Default shared stock remains **six FirstAidKits and one Medikit**. The stock respects `LOOT_BLACKLIST`; strict whitelist mode also intersects it with `LOOT_WHITELIST_ITEM`. Modes 0/2 retain the curated profile minus the blacklist. Empty profiles skip deployment; unavailable/disallowed entries do not produce replacements.

| Setting | Default / constraints |
| --- | --- |
| `BW_SUPPLY_ENABLED` | `true` |
| `BW_SUPPLY_CHANCE` | `0.20`; finite 0–1 |
| `BW_SUPPLY_CLASS` | `Box_NATO_Equip_F`; inventory ammunition-box class, sufficient capacity, excludes Support-box descendants |
| `BW_SUPPLY_STOCK` | `[["FirstAidKit",6],["Medikit",1]]`; only those classes, positive integer quantities, hard caps six/one, no duplicate multiplication |
| `BW_SUPPLY_LIFETIME` | `180`; positive, at most 600 seconds; shared by both families |
| `BW_SUPPLY_RELOCATION` | `75`; positive, at most 100 metres; shared by both families |
| `BW_SUPPLY_AIRCRAFT` | `B_T_VTOL_01_vehicle_F`; loaded Air class with crew; shared delivery class |
| `BW_SUPPLY_DELIVERY_TIMEOUT` | `180`; positive, at most 300 seconds |
| `BW_SUPPLY_DESCENT_TIMEOUT` | `120`; positive, at most 180 seconds |

## Engineering contents and settings

The server resolves one manifest per successful roll. Multi-unit categories draw each unit's class independently and aggregate duplicate selections.

| Category | Default quantity / hard cap | Curated classes |
| --- | --- | --- |
| AP mines | 1–2 total / 2 | `APERSMine_Range_Mag`, `APERSBoundingMine_Range_Mag`, `APERSTripMine_Wire_Mag` |
| AT mines | 1–2 total / 2 | `ATMine_Range_Mag`, `SLAMDirectionalMine_Wire_Mag` |
| Fragmentation grenades | 1–3 total / 3 | `HandGrenade`, `MiniGrenade` |
| Smoke | 2 total | `SmokeShell` |
| Engineering tools | One of EACH configured/allowed tool | `MineDetector`, `ToolKit` |

Mines/grenades/smoke are magazine cargo; tools are item cargo. Generation never spawns live explosives. No demolition charges, satchels, IEDs, dispensers, rockets, rifle ammunition or additional assets are included.

| Setting | Default / constraints |
| --- | --- |
| `BW_ENGINEERING_ENABLED` | `true`; independent of medical |
| `BW_ENGINEERING_CHANCE` | `0.20`; finite 0–1, independent roll |
| `BW_ENGINEERING_CLASS` | `Box_NATO_Equip_F`; same class/capacity validation as medical |
| `BW_ENGINEERING_AP_POOL` | Subset of the AP classes above |
| `BW_ENGINEERING_AT_POOL` | Subset of the AT classes above |
| `BW_ENGINEERING_GRENADE_POOL` | Subset of the fragmentation classes above |
| `BW_ENGINEERING_SMOKE_POOL` | Subset of `["SmokeShell"]` |
| `BW_ENGINEERING_TOOLS` | Subset of `["MineDetector","ToolKit"]` |
| `BW_ENGINEERING_AP_COUNT` | `[1,2]`; inclusive integer range within 0–2 |
| `BW_ENGINEERING_AT_COUNT` | `[1,2]`; inclusive integer range within 0–2 |
| `BW_ENGINEERING_GRENADE_COUNT` | `[1,3]`; inclusive integer range within 0–3 |

All categories respect `LOOT_BLACKLIST`. Strict whitelist mode requires tools in `LOOT_WHITELIST_ITEM` and all magazines, including smoke, in `LOOT_WHITELIST_EXPLOSIVE`. Modes 0/2 consider only curated candidates. Invalid/noninventory classes are excluded. Malformed pools/ranges reject the manifest. Empty categories transfer no budget elsewhere; at least one AP or AT mine must remain in the final stock or the engineering deployment skips. Combined item/magazine mass must fit before publication. Invalid chance values prevent deployment; zero cannot succeed, one always attempts placement.

Tools only provide existing native/mod interactions. No engineer trait or new repair service is granted. Remove `ToolKit` from the tools pool if native repair is unavailable for the playable roles/mod setup. Native detection/repair and mine friendly-damage behavior require in-game checks. The existing custom disarm actions remain unchanged and are not a validated salvage system. Long-session deployed-mine accumulation is an acceptance concern, not an implemented limit.

## Placement, ownership and display

Per family, sample at most **24 open outdoor landing zones** at 150–300 metres, then at most **12** fallback candidates at 100–150 metres. Indoor positions are no longer used. Checks cover bounds, water, support/slope, clearance/headroom, approach, roads, clutter and clear sky to 300 metres. Reserve the site atomically before flight, respecting 20-metre cross-family separation. On landing, recheck actual ground support/access and separation: drift must remain within 60 metres of the chosen zone and the landed crate within 100–350 metres of the captured anchor. Reject unsafe landings instead of teleporting the box to the original site. Geometry checks still do not prove a walkable route.

One worker per family performs placement then checks only its tracked crate each second. Captured wave/truck checks prevent late publication during preparation or after cancellation. A validated family definition chooses record/snapshot keys. Both families share a monotonic instance serial and the same start/watch/end code. Cleanup matches family and ID, clears only that snapshot, deletes only that crate and terminates only its worker. Explicit wave/mission cleanup also handles failed workers. Existing lifecycle calls without a family argument still mean medical.

Manifests now use `[cargoTag, classname, quantity]` entries (`item` or `magazine`). The medical configuration remains class/count pairs; only the internal output format changed. All cargo is cleared before the validated manifest is added with the appropriate global command. Crates use normal parachute physics while descending and are damage-protected/empty during delivery. After validated landing, simulation is disabled and normal damage is restored. The existing tag excludes them from mission construction pickup/move/sell. External mod logistics still need testing. No claim RPC or JIP action queue is introduced. Broad existing remote-execution/public-variable transport is not complete malicious-client hardening.

Ordinary loot spawn/discovery/cleanup is unchanged and does not own these crate classes. Default caches are outside the nearby `Box_NATO_Support_F` FAK-conversion scan. Medical stock moved into the truck or other conversion containers can be processed at the existing ten-FAK cost.

`BW_SUPPLY_STATUS` and `BW_ENGINEERING_STATUS` each publish `[id, crate, position, expiresAt, wave]`. F12's existing client tick maintains two WEST-local markers, two independent countdown lines and per-family warning IDs. Medical is green; engineering is orange, with explicit English/Polish labels. JIP/HUD recreation recovers current state; local expiry/destruction hides stale display data. Separate `BW_SUPPLY_DELIVERY_STATUS` / `BW_ENGINEERING_DELIVERY_STATUS` snapshots contain `[id, landingZone, wave, deadline, stage]` for `inbound` or `descending`. They clear on landing/cancellation. F12's team-status array and the landed-cache snapshot shapes are unchanged. Ammunition and salvage reward families remain deferred.

## Validation

`tests/supplyCache.sqf` exercises medical policy/caps, chance guards, real workers/cargo, preparation survival, stale/repeated cleanup, depletion, expiry, relocation/replacement/movement, extraction/endings and ordinary-loot separation. It now asserts the tagged medical format. Use only a disposable idle server/editor with a living WEST human, a valid nearby site and neither family's worker active. It invokes ordinary loot cleanup and deletes nearby loose loot.

`tests/engineeringCache.sqf` additionally requires two real separated sites. It tests 100 generated manifests for category invariants, strict typed whitelists, invalid ranges, unchanged medical stock, all four 0/1 chance combinations, real mixed cargo, unique IDs, two-family cleanup, same-site publication races, invalid tags/roots and both-family ending/relocation cleanup. The medical/engineering stock harnesses temporarily replace the site selector and transport completion for fast deterministic lifecycle cases after finding real fixture sites. Both save/restore globals/functions and report local failure lists to RPT. They do not run aircraft delivery.

`tests/supplyDelivery.sqf` exercises the real delivery, worker, parachute and cleanup code with a stationary vanilla helicopter and controlled transit/landing fixtures. It covers inbound loss/extraction/timeout, empty airborne cargo, post-landing stock/lifetime/smoke, descent phase-cancellation/timeout/drift, explicit cancellation and in-flight family isolation. It restores the wrapped spawn/transit/site functions and globals. Preconditions: disposable idle server/editor, no caches, living WEST human and two clear separated landing zones. It does not prove real VTOL navigation or wind/landing physics.

Hosted/dedicated acceptance still required: simultaneous last-item transfers, reconnect/respawn/JIP with both caches, independent expiry/destruction, collection at ready-skip boundaries, actual mine placement/detection and native tool interactions, `TEAM_DAMAGE` on/off, transport/mod logistics, representative route access, UI scales/localization, and long-session mine/object/worker counts. Cache expiry must preserve collected and placed explosives.

No Arma/SQF runtime is available in the current tooling. None of the cache/delivery harnesses has been executed here; source checks are not compilation or gameplay validation. No PBO was built.

Engineering-source verification passed: delimiter/string checks in 16 changed SQF/config files; three new function registrations and loot call references; independent 20% defaults and preserved medical quantities; wave hook order, direct-remote/family guards, typed cargo and separation references; local links in seven changed guides; stable 24-entry backlog. XML parsing and placeholder checks passed for all 20 English/Polish entries. These are static checks, not execution of the regression scripts.

Paradrop-source verification (2026-10-30) passed: delimiter/string checks in 16 changed SQF/config files, two registrations and loot references, stock/expiry sequencing after delivery, asset cleanup before worker termination, preserved medical defaults and officer UI, and local links in eight guides. XML parsing/placeholders passed for all 29 English/Polish entries. Fourteen regression scripts are present; the new delivery harness has not been executed. Real VTOL approach, wind/descent, landing access and multiplayer/JIP still require Arma.
