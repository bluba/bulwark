# Bulwark fixes

## Placeable FPV drone supply crate (2026-10-31)

Moved the 3,000-point FPV supply kit from Support to Supplies, ID 9003. Preserved its complete stock using magazine/item/backpack cargo, class/mass validation and the existing atomic paid placement transaction. Removed the old communications entry and delivery dispatch; standard ammo support is unchanged. Missing FPV content fails without charge. Extended the hosted shop harness; Arma acceptance remains pending.

## Supplies shop purchases (2026-10-31)

Medical and engineering crates now appear in a separate Supplies tab, priced at 3,000/3,000 personal points by default through `BULWARK_SUPPLYITEMS`. Server transactions validate caller, ID, price, holding slot, stock and capacity, then create/fill/debit once and invoke the ordinary purchase-placement callback. The tab does not require the Support unlock. Engineering stock is randomized once per purchase and remains finite through pickup/movement.

Removed automatic wave-start calls and chance settings; the legacy automatic entry point is a no-op. Paid crates have no temporary cache ID, delivery, marker, expiry or wave/relocation cleanup. The ordinary Support Drop remains a separate support. Added `tests/supplyShop.sqf`; retired the three superseded cache/drop harnesses. UI, actual placement and dedicated-server acceptance remain pending; no PBO built.

## Early-wave vehicle overproduction (2026-10-30)

Wave-six investigation found three inclusive zero-based count loops. Ordinary helicopter/truck transport rolls spawned two vehicles each at early waves, and a wave-six convoy spawned three trucks. Transport counts now use explicit positive integer random counts (one vehicle at wave six) and one-based loops; a wave-six convoy now requests two trucks. Player scaling uses connected humans rather than occupied lobby/AI slots. Added per-category `Bulwark vehicles:` RPT logging to diagnose requested counts during play.

Four independent automatic vehicle rolls can still stack with a convoy/paradrop special; there is no unconditional wave-six event. The original probability and eligibility rules are retained. See [SPECIAL_WAVES_REVIEW.md](SPECIAL_WAVES_REVIEW.md) for exact default wave-six probabilities and before/after counts. Source-level checks passed; in-engine verification is pending.

## Debug Zeus reset (2026-10-30)

Added **Reset Zeus** to Shop + > DEBUG beside the enemy-kill button. The fixed server action unassigns/reassigns `mainZeus` to the requesting host/admin's current unit, retaining existing shop proximity, caller validation and cooldown checks. Missing/conflicting modules and another living player's assignment are refused with feedback. Reset remains available during forced-wave transitions. Close the shop and press Y after a moment to enter Zeus. Source structure/wiring/layout checks passed; Arma UI and multiplayer recovery tests remain unrun. No PBO created.

## Respawn clearance from the truck (2026-10-30)

The old placement helper tried positions only 2 m from the truck center and ignored the truck in its intersection check. It could also fall back to that center. The replacement searches empty ground beyond a footprint-based exclusion circle: at least 12 m from the center, or the model's horizontal corner radius plus 6 m for larger vehicles. Search candidates avoid nearby vehicles and their projected three-second movement paths, water, occupied infantry positions and blocked standing space. Results retain the ASL coordinate contract and place feet just above terrain rather than at the truck's floor height.

There is no fallback inside the truck. If the bounded search finds no suitable ground, respawn retries once per second with damage temporarily disabled; the player's previous damage setting is restored after placement. Initial-spawn relocation uses the same respawn script. The legacy teleport support also uses this helper and now rejects/refunds an unavailable destination instead of applying an empty position. This prevents unsafe initial placement; it does not prevent a driver deliberately running into a player afterward.

Added `tests/respawnClearance.sqf` for real-helper null handling, rotated vanilla/PSZ truck clearance, terrain-height conversion, vehicle obstacles and moving-truck prediction. Static checks passed; this engine harness, concurrent dedicated-server respawns and live driving still need Arma verification.

## Friendly reinforcements follow the mobile Bulwark (2026-10-29)

Purchased infantry and mobile crewed allies now register one server controller per group after placement. Orders execute on the current group owner, including an HC. Groups follow the actual `bulwarkBox` when it moves, then resume their assigned patrol or camp guard duty after six seconds without detected movement. Infantry patrol targets are within 50 m of the truck; camp groups guard a position around 20 m away. Mobile allies beyond 75 m horizontally are recalled and remain in regroup mode until within 45 m. These are movement orders, not teleportation: terrain, speed and combat can temporarily exceed the boundary. A truck can outdrive infantry.

Support paratroopers now retain their own autonomous group and enter the same controller after insertion, rather than joining the caller's player-led squad. Player-containing and Zeus/remote-controlled groups are excluded. Carried purchased allies pause their task and resume after placement. Static weapons remain emplaced with their crews; they cannot physically follow and must be moved by players. Crewed ground vehicles/helicopters receive follow orders and hold near the truck when settled; the horizontal recall range does not constrain aircraft altitude.

Camp duty uses a bounded HOLD guard position rather than LAMBS taskCamp's asynchronous animations and split-off patrols, so old camp callbacks cannot freeze a unit after relocation. Patrol uses the existing LAMBS taskPatrol integration with teleportation and dynamic reinforcement disabled. Task resets preserve group identity. A short owner-local lease releases controller overrides when dispatch stops.

Added `tests/friendlyBulwark.sqf` for actual controller registration, relocation, patrol bounds, camp, held-state and takeover/static exclusions in an idle hosted editor session. Static checks were run; this harness has not been run in Arma. Dedicated-server/HC transfers, live driving, helicopter navigation and parachute landing remain engine-test requirements.

Integration references: upstream LAMBS [taskPatrol](https://raw.githubusercontent.com/nk3nny/LambsDanger/master/addons/wp/functions/fnc_taskPatrol.sqf), [taskCamp](https://raw.githubusercontent.com/nk3nny/LambsDanger/master/addons/wp/functions/fnc_taskCamp.sqf) and [taskReset](https://raw.githubusercontent.com/nk3nny/LambsDanger/master/addons/wp/functions/fnc_taskReset.sqf). The installed version still needs verification.

The current working mission is `dynamicBulwarks.Altis`, the parent of this docs directory. Earlier records call it `Altis.bulwarkFixed`; the old checkout and original Workshop archive are not present in this workspace. `BASELINE_REVIEW.md` records the pre-fix findings; its line numbers describe that original snapshot.

## Changes

- F15 delivery revision (2026-10-30): medical and engineering caches now arrive via the active support drop's VTOL/parachute/blue-smoke behavior. Open landing zones replace indoor placement. Stock and its lifetime start after safe landing; flight/descent have deadlines, in-flight JIP labels and family-owned aircraft/crew/chute/smoke cleanup. Contents and independent 20% rolls remain. Added `tests/supplyDelivery.sqf`; real flight/landing acceptance is pending.

- F15 engineering caches now roll independently at 20% beside medical caches. Random bounded AP/AT mines, fragmentation grenades, smoke and tools use typed item/magazine cargo and existing loot restrictions. Shared family-aware lifecycle code isolates rolls, workers, cleanup and JIP snapshots; at most two caches publish at least 20 metres apart. F12 displays both. Cache removal leaves collected/placed explosives intact. See `SUPPLY_CACHES.md`; engine acceptance is pending.

- F15 deployment now rolls independently at 20% each combat wave, including wave one, instead of a fixed interval. Misses consume the wave's attempt to prevent rerolls. `BW_SUPPLY_CHANCE` replaces the former first-wave/interval settings; the singleton and lifecycle rules remain.

- F15 adds one finite medical-cache family, scheduled independently of ordinary loot and hostile jobs. Server-owned instances validate stock/placement, survive preparation and clean up on depletion, expiry, movement, next combat or mission cancellation. F12 shows the local marker/countdown with English/Polish labels. See `SUPPLY_CACHES.md`; engine/multiplayer validation is pending.

- F12 extends the points HUD with shared wave/phase, ticket, bank and public objective state. Four manual tactical ping types use owner-validated server requests, UID cooldowns, expiry and bounded map markers. Existing phase/action ticks handle JIP snapshots, corpse/disconnect cleanup and HUD/action recovery. See `TACTICAL_STATUS.md` for controls and multiplayer checks.

- F01 adds a server-controlled ready-to-skip intermission vote with strict majority, live eligibility, phase-bound caller validation and a JIP/respawn-safe self-action. The preparation timer shows vote counts; a shared deadline preserves the final warning without appending a second countdown. Defaults allow a skip after 15 seconds plus the final 15-second warning. See `READY_VOTE.md` for eligibility, settings and multiplayer validation.

- Extraction recalculates the current roster on each poll. All living human players, including unconscious survivors, must be within 100 metres, and at least one must be conscious. Dead players and headless clients are excluded. Success is handled during combat and takes priority over defeat or the wave limit.
- Bonus objectives now start with the combat wave, use their own marker and wave token, and expire at wave end. Bank bonuses are applied in a non-suspending server operation.
- Enemy FOBs have a marked, destructible ammunition cache. Destroying it stops reinforcement production. A living cache prevents premature wave completion. Stationary defenders are exempt from anti-stuck deletion; surviving defenders attack after their cache is destroyed.
- A shared damage handler returns the existing hitpoint damage when protection applies, including friendly vehicle fire identified through the instigator. Revival runs on the player's owning machine, consumes the kit there, heals immediately and maintains the 15-second protection flag.
- FAK conversion processes ten kits per Medikit, preserves leftovers and all unrelated items, deduplicates nearby containers and polls every two seconds. Instructions now match the ten-kit cost already used by the old code.
- Bank transfers validate the caller, distance, integer amount, limit and available balance on the server. Debit and credit happen together. Purchases send catalogue IDs; the server resolves the price/class, checks payment, creates the object or grants the support, and reserves the player's holding slot before replying. Legacy purchase entry points use this same path.
- Ticket purchases use the validated server catalogue. A death reserves its own ticket on the server, so the final ticket pays for that respawn instead of disabling it. Corpse-bound responses prevent a delayed message affecting a new life. Configured combat delay is kept separate from free intermission respawns. Pending paid respawns prevent an early defeat; final defeat checks use fresh state every second throughout the grace period.
- Healing and spin-box payments also run on the server. Spins have a per-box lock, and loot-box relocation uses a finite position pool. Healing now requires the advertised 200 points.
- Friendly supply drops no longer create unrelated enemy infantry. They retain the existing medical and optional PSZ anti-tank supplies, with class checks. Flight/landing waits have deadlines and cleanup. Friendly paratrooper support has valid syntax, per-flight state and bounded arrival checks.
- Enemy mortar instances unpack their vehicle/crew/group into private variables, fire on the mortar object and end with their wave. Artillery/Grad jobs capture their wave token, stop producing rounds during intermission/extraction and no longer share direction or wave variables.
- Special-wave disable and enemy-vehicle start/Never options are respected. The second late-game modifier is added to the execution list. Duplicate night modifiers no longer overwrite the saved daytime.
- Parameters use numeric integer values and matching defaults/labels. `MAX_WAVES=-1` means unlimited. `RANDOM_WEAPONS` is 0/1. `HOSTILE_MULTIPLIER` uses 50/100/200/300, divided by 100 in mission configuration; update server-side overrides that used the old 0.5/1/2/3 values.
- Enemy spawners have private faction/class state, validate loaded classes, select integer squad sizes from one to five and count created units. Missing infantry tiers or the required Bulwark truck produce an explicit startup failure instead of silent empty waves.
- LAMBS task changes are issued once per group. Purchased infantry patrol using the catalogue range at placement; vehicle/static crews hold their emplacement. Transport and aircraft waits observe cancellation and timeouts. Copied helicopter code no longer calls the absent `Scripts/LimitEquipment.sqf`.
- Loot selection prefilters buildings with usable positions, so an industrial area cannot trap wave startup in an endless retry. Map strikes prefer the selected target, falling back to full network-owner marker IDs held in private state.

## Validation

Earlier work used `node tools/validate-baseline.cjs` for lexical, registration, reference, lobby-parameter and integration checks. That tool and its extraction manifest are absent from this workspace. Recent F01/F09/F12 changes received targeted source checks documented in their feature notes; these are not SQF compilation or engine simulation.

The earlier `tools/build-pbo.cjs` packaging tool is also absent. No PBO was built for these feature changes; packaging remains outside the current instruction.

The source contains `tests/regression.sqf`, an isolated server/editor regression script that calls the actual inventory conversion and extraction predicate functions. It checks 0/9/10/20/25 FAKs, preservation of other cargo, repeat conversion, repeated visits by one of four units, whole-team arrival, leaving the zone, an empty roster and an entirely unconscious team. It creates temporary objects away from the truck and removes them.

No Arma engine/compiler was run in this workspace. The in-game regression script and multiplayer checks below remain to be executed.

## In-game checks still needed

1. Dedicated server with two clients: simultaneous bank withdrawals/purchases; final ticket; buying tickets after depletion; configured delay in the next wave; death/reconnect during a pending respawn.
2. Four players: one at extraction for several polls; all survivors arriving while enemies remain; one unconscious survivor outside/inside; successful extraction during the defeat grace period.
3. Reach a bonus during combat; destroy the FOB cache while unrelated enemies remain; kill all defenders while leaving the cache intact; check multiple stacked FOB/mortar specials.
4. Destroy each support/hostile aircraft before arrival; move targets; let transit time out; move the Bulwark near non-enterable buildings. Confirm no orphan enemy infantry are created by friendly deliveries.
5. Disable specials, set vehicles to Never, select unlimited waves and both random-weapon options. Test every numeric multiplier and apply updated server overrides.
6. Place purchased infantry, crewed vehicles and static weapons; verify AI locality, range and inventory. Run several combined-special waves to check LAMBS interaction and long-session cleanup.

## Compatibility boundaries

The required content still includes PSZ, CUP, RHS and LAMBS as used by the scenario's class catalogues. Function signatures for the changed LAMBS patrol/rush integration were checked against its upstream source, but the installed mod version needs an in-game check.

The original broad `CfgRemoteExec` compatibility configuration is retained. These changes validate gameplay transactions but do not claim comprehensive protection against malicious clients modifying public variables or calling other legacy entry points. Headless-client scoring and dormant experimental scripts such as `checkBulwark.sqf`/`fn_himarsStrike.sqf` remain outside the active gameplay fixes; they were not enabled.

## Special-wave follow-up

Drone firing now checks for living groups and targets and uses the UAV object; the cap is 15 and UAVs/crew are tracked for cleanup. Civilian spawns use a finite building-position pool. Suicide proximity/audio/movement applies only to tagged bombers. Aircraft capture their originating wave and choose their run count once. Squad spawning reuses the created group and removes failed empty groups. See SPECIAL_WAVES_REVIEW.md for remaining selection and balance concerns.

## Streaming enemy budget

Removed the post-wave-10 multiplier: the ordinary infantry budget now scales linearly with wave number. The active hostile limit is set at wave start to min(120, 30 + 4 × human players). Ordinary infantry can fill 80% of that limit; special troops and vehicle crews can use the remainder. All living EAST/RESISTANCE units count, including Zeus units and vehicle crews. External Zeus/mod spawns are counted but cannot themselves be prevented by this gateway. Civilian extras and friendly units are outside the hostile limit.

Server-side reservations serialize capacity allocation across concurrent producers. Full requests wait and retry every five seconds, then spawn whole squads when space is available. Vehicle crew slots are estimated conservatively from driver/turret configuration. Queued transport/FOB troop requests also cancel if their carrier/cache is destroyed. Extraction and wave cancellation stop waiting requests. The mission monitor runs while spawning continues; completion requires no remaining infantry budget, no finite producer jobs, no queued reservations, no hostile units and no live FOB cache. Transport cleanup may delay completion until its producer finishes.

Example: 25 players, team multiplier 0.5, infantry multiplier 2, wave 30 gives 720 ordinary infantry total, an active limit of 120, and an ordinary threshold of 96. Difficulty tiers and existing special-selection probabilities are preserved.

Added tests/spawnCapacity.sqf for an idle editor/server: exercises the real gateway's ordinary quota, reserved special capacity, casualty replenishment, concurrent waiting and extraction cancellation. This test requires Arma and has not been run here. Static integration checks cover all active hostile spawn paths; dormant legacy scripts remain outside the gateway.

## Unique weather/time modifiers

Every special draw now filters out fog/night already present in the wave plan. It draws from the remaining pool directly, so there is no retry loop and duplicate weather does not waste a slot. Combat specials remain repeatable. Vehicle specials disabled by the start-wave/Never setting are excluded before selection as well, preventing a replacement from being discarded later. An entirely ineligible pool adds nothing (for example the vehicle-only guaranteed pool when vehicles are disabled). Special probabilities and slot counts are unchanged.

## Enemy AI behavior fixes

Fixed the findings recorded in AI_BEHAVIOUR_REVIEW.md: singleton defense watching with tagged-bomber checks; removal of permanent ordinary-infantry obstacle overrides; conservative on-foot anti-stuck cleanup; one owner-local infantry controller with tracked LAMBS handles; protected transport insertion; group-level creep selection; dedicated bomber movement; CQB hysteresis; bounded helicopter approach; safe target fallback; and unambiguous wave 20–24 skill (kept at 0.4). Active LAMBS resets preserve group references. Tests/aiBehaviour.sqf supplies an in-engine regression harness, not yet executed. The owner-side takeover check uses remoteControlled (Arma 3 2.14+). No PBO generated.

## F09 recurring FOBs

Implemented 2026-10-29: the ranked first slice of F09. New FOB types are still deferred.

- The existing reinforcement-cache FOB can be selected from wave 7 onward, including the later-wave primary special pool. It uses the existing special-wave probability; it is not a guaranteed event and does not add another special slot. Adding it to the later pool changes the relative share of the other primary specials.
- `BW_FOB_COOLDOWN_WAVES = 2` in `editMe.sqf` means two intervening waves without a new FOB: a successful deployment in wave 7 permits the next one from wave 10. A value of 0 permits consecutive waves, but never a second deployment in the same wave. The first eligible wave remains 7.
- Selection filters unavailable FOBs before drawing. A shared predicate checks minimum wave, Specials Off, duplicate selection, active cache, pending setup and cooldown. The producer checks eligibility again while atomically reserving the singleton setup slot. Cooldown is committed only when a live cache has been created; missing infantry classes and cancelled/failed cache setup do not consume it.
- Specials Off disables FOB selection and direct producer execution. Vehicle Never does not exclude this infantry-only objective. Defector waves still use the existing RESISTANCE faction/classes.
- The wave monitor tracks the FOB producer from dispatch until cache destruction and defender handoff, including time spent waiting for enemy capacity. A live cache remains mandatory for wave completion.
- Cache destruction/deletion cancels pending teams. Teams created while the cache or wave disappears are discarded before registration. Surviving established defenders are released to the assault controller. The producer then finishes, while a separate wave-bound cleanup task retains scenery until intermission; this avoids a circular wait between producer completion and wave completion.
- Extraction/intermission cancellation removes the FOB's owned troops and objects and clears its marker and active-cache record. Existing hostile capacity limits, three ten-man initial garrison teams and the 125-second reinforcement interval are retained.

Validation performed here: balanced string/comment/delimiter checks for seven changed SQF/config files; Bulwark registered function files and quoted SQF references resolve. These are static checks, not SQF compilation. No PBO was built and no Arma executable/test session was run.

Added `tests/fob.sqf`, which calls the actual availability predicate, FOB producer and spawn gateway. In an isolated idle editor/server with mission configuration/functions loaded, run:

```sqf
[] execVM "tests\fob.sqf";
```

The normal mission loop must be disabled and the hostile battlefield empty. Run with Specials enabled and LAMBS loaded, then repeat with Specials disabled. The script checks first/later-wave eligibility, duplicate plans and concurrent producers, failed setup, live/pending singleton slots, cooldown boundaries including zero cooldown, cache deletion during capacity waiting, extraction cancellation and real defender handoff. Results are logged and retained in `BW_fobTestFailures`. It restores the globals it changes and cleans up its test actors.

In-engine acceptance still pending: execute that harness; play later waves with Specials Off and vehicles Never; verify a living cache blocks completion after its defenders die; destroy the cache with defenders alive and while capacity is full; verify next-wave scenery/marker cleanup, JIP objective visibility and installed-mod LAMBS behavior on a dedicated server.

## Special-wave follow-up — 2026-10-29

Addressed review findings 2–4: surviving mortar crew regain rush/controller eligibility; the capacity gateway discards results when the guard or wave disappears during creation, with additional cargo checks in truck/helicopter callers; paradrops require a current pass within 250 metres after capacity allocation, with a protected inactive pending troop and a 120-second return timeout. Failed return/cancellation removes that troop and ends the batch. See [SPECIAL_WAVES_REVIEW.md](SPECIAL_WAVES_REVIEW.md) for behavior and engine acceptance cases.

Extended `tests/spawnCapacity.sqf` with successful guarded creation and injected guard deletion / wave cancellation after real group creation, checking cleanup and reservation release. The harness is unrun. Static string/comment/delimiter checks passed for six changed SQF files; four relevant function registrations and source files resolve. No Arma execution or PBO build occurred. Review finding 1 (untracked mortar shells remaining airborne into preparation) remains open.

## Thunderstorm special — 2026-10-29

Added a unique thunderstorm modifier to beginner/full pools and later standard-modifier draws. Full overcast, 85% rain and ambient lightning accompany ground-strike attempts after 20–35 seconds, then every 35–65 seconds. Bounded land-site selection avoids living players, the Bulwark and nearby structures/vehicles. Disposable server-owned targets feed the native lightning module on the server/viewers; tagged/wave/phase/age/sender guards and local deduplication protect dispatch. Strikes are not queued for JIP. Existing client ticks apply the published lightning snapshot, with manual lightning override enabled in mission.sqm.

The singleton persistent worker does not gate wave completion. Explicit intermission/mission-end cleanup and worker cancellation restore saved cloud/rain/lightning values and remove strike targets. Fog/night remain independently owned. See [THUNDERSTORM.md](THUNDERSTORM.md) for behavior, native-function references and acceptance cases.

Added an unrun idle-session `tests/thunderstorm.sqf` harness with native lightning stubbed for state/guard/lifecycle checks. Static lexical checks passed for 12 SQF/config files; all 43 Bulwark function files and 16 active script references resolve. Targeted selection, cleanup, JIP-tick and override checks passed. Native damage locality, visuals, dedicated/JIP weather and fog/night stacking still require Arma acceptance. No PBO created.

## Officer Hunt — 2026-10-29

Implemented the [Officer Hunt plan](OFFICER_HUNT_IMPLEMENTATION_PLAN.md); current behavior and configuration are in [OFFICER_HUNT.md](OFFICER_HUNT.md). The later primary pool now includes a wave-10+ command post with an officer/four guards, a fixed approximate search area and localized HUD/notices. Reciprocal selection/setup checks prevent FOB stacking; singleton and successful-deployment cooldown permit wave 10 → 13 by default.

One registered lifecycle producer monitors the officer independently of a separately registered finite reinforcement child. Four-man teams request admission every 90 seconds, capped at two living tracked teams/eight soldiers and one pending job. The shared spawn gateway accepts an optional absolute deadline, defaulting to -1 for existing callers; admission/wait/post-creation expiry releases capacity and discards results. Reinforcement deadlines cannot outlive the objective. Officer death/deletion cancels further requests; ten-minute expiry releases the surviving command squad to assault. Ordinary infantry budget and existing kill scoring remain unchanged; there is no extra bank reward.

Owner-local patrol/task leases stop on phase/ownership/takeover changes. Assault handoff clears every stationary/scripted exclusion. Cleanup tracks original units across group transfers and dispatches cancellation deletion to their owners for local takeover checks. Existing phase ticks provide independent producer-failure recovery. Setup/active/closing state and instance IDs protect cooldown, JIP snapshots, child drainage and stale cleanup; explicit intermission/next-wave/mission-end hooks are present.

Added an unrun real-producer `tests/officerHunt.sqf` harness and extended `tests/spawnCapacity.sqf` with three deadline cases. Source checks passed for 23 SQF/config files, 52 function files, 17 script references and 101 Bulwark references; targeted lifecycle/selection/cap hooks passed. XML and placeholder parity passed for 25 keys, and 76 documentation links resolve. No SQF compilation, engine regression, multiplayer/HC/Zeus acceptance or PBO build was performed.

## Shop Debug tab — 2026-10-30

Added DEBUG alongside BUILD/SUPPORT in Shop +, using a shared visibility switch and a separate button panel. **Kill all enemies** sends a fixed action ID to a server-only handler. Caller ownership, shop proximity, living/conscious state and host/dedicated-admin permission are checked on the server; ordinary clients see a disabled button. A two-second per-UID cooldown prevents duplicate execution, and requester feedback plus an RPT entry record the result. The command kills current non-player EAST/RESISTANCE units, including crews; queued reinforcements, budgets, FOB caches and phase state remain unchanged. Hidden purchase dispatch is rejected while Debug is selected.

Added `tests/debugShop.sqf` for the actual handler and documented UI/dedicated/HC/security acceptance in [DEBUG_SHOP.md](DEBUG_SHOP.md). Static checks passed for nine SQF/config files, both registrations, new control IDs, layout bounds and server guard/remote-target references. The harness and rendered/gameplay UI have not been run in Arma. No PBO created.

## Debug forced special waves — 2026-10-30

The Debug panel now lists all 15 implemented specials with a **Force selected special** button. The validated host/admin request queues one transition; the mission loop closes combat, cancels event/supply/weather state, deletes current enemies/tagged enemy vehicles and FOB caches, drains producer/queue work, then starts the next wave number with exactly the selected modifier plus ordinary infantry. Preparation, random modifier stacking and automatic enemy vehicle additions are skipped for that forced wave. Exact wave/type exceptions bypass selection gates without mutating lobby settings; capacity, singleton and content/placement checks remain. Normal random behavior resumes on the following wave. Requests during preparation/countdown are supported; extraction retains priority.

Spawn tickets now include their originating script handle for safe orphan recovery, and vehicle results carry a server-local wave tag so empty enemy transports can be removed without selecting friendly vehicles. Truck departure/cleanup waits respond to cancellation. Negative/absent officer instance IDs are rejected harmlessly during repeated cleanup. Native effects already in progress and the existing untracked mortar-round limitation remain as documented in [DEBUG_SHOP.md](DEBUG_SHOP.md).

Extended the debug-shop harness with special-ID/busy-transition admission cases and added an unrun `tests/debugForceWave.sqf` for real cleanup, pending/orphan queue drainage, hostile vehicle deletion, friendly preservation and exact override scoping. Static lexical checks passed for 19 SQF/config/test files; 57 Bulwark function files resolve; all 15 unique catalogue keys match dispatch cases; forced faction/transition order and new UI IDs/bounds passed. No SQF compilation, actual all-special mission transitions, UI/dedicated/HC tests or PBO build were performed.

## FPV Operator source implementation (2026-10-30)

Station lifecycle, bounded crewless drone director, target fairness/cover checks, optional-addon wave selection, Debug entry and PL/EN HUD/search area are implemented. See [FPV_OPERATOR.md](FPV_OPERATOR.md) and [addon integration](FPV_MOD_INTEGRATION.md). Fixed settlement candidates supplement explicit sites/markers; they are not editor-verified navigation points. Static checks passed; the adapter/lifecycle harnesses and in-game multiplayer/flight/detonation acceptance remain unrun.
