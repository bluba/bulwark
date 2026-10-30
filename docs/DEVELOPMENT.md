# Development, validation and debugging

## Working directory

The workspace root is the active dynamicBulwarks.Altis mission. Make gameplay edits in its subsystem directories and keep Markdown documentation under docs/. Earlier records use Altis.bulwarkFixed; the old checkout, extraction manifest and tools directory are not present here.

Do not create a PBO under the current user instruction. The build-pbo.cjs tool and earlier PBO referenced by historical notes are not supplied in this workspace.

## Static validation

The earlier tools/validate-baseline.cjs validator and extraction manifest are absent. Do not treat its historical invocation as an available command or a fresh test result. Recent F01/F09/F12 changes were checked with targeted lexical, function-registration and reference checks. F12 also received XML parsing and translation-placeholder checks; its exact recorded coverage is in [TACTICAL_STATUS.md](TACTICAL_STATUS.md).

These source checks do **not** compile SQF, resolve every mod class, emulate scheduling/locality, validate UI behavior or measure performance. A passing result cannot justify saying multiplayer behavior has been tested. Recheck changed SQF/config delimiters and strings, function registrations, script references and relevant configuration; check stringtable.xml parsing and placeholders when editing translated UI. Record the actual check scope and result.

When adding a CfgFunctions function, register it in the appropriate Functions.hpp, keep its fn_ filename consistent and confirm description.ext includes that subsystem. Search call sites before removing legacy APIs.

## Arma regression scripts

These scripts are manual tools, not startup code. Read the preconditions in each file before running them on the server in a disposable test session.

| Script | Coverage / preconditions |
| --- | --- |
| [regression.sqf](../tests/regression.sqf) | Inventory conversion and extraction predicates; temporary objects are created and removed. |
| [spawnCapacity.sqf](../tests/spawnCapacity.sqf) | Actual spawn gateway: ordinary quota, special reserve, casualty replenishment, extraction cancellation and guard/wave loss during group creation. Temporarily wraps/restores BIS_fnc_spawnGroup. Requires idle mission loop and no hostile units. |
| [aiBehaviour.sqf](../tests/aiBehaviour.sqf) | Actual AI controller and defense watcher: task replacement, group identity, CQB thresholds, bomber mode, exclusions, singleton/pickup behavior. Requires idle hosted editor/server, a living player and LAMBS. |
| [fob.sqf](../tests/fob.sqf) | F09 availability, singleton/cooldown, producer and capacity cancellation. Idle server with no hostiles/FOBs; run with specials enabled and disabled. LAMBS required for defender handoff. |
| [readyVote.sqf](../tests/readyVote.sqf) | F01 duplicate/stale requests, minimum delay, strict majority, eligibility cleanup, one deadline commit and extraction/combat rejection. Idle server and at least one living conscious WEST human. |
| [tactical.sqf](../tests/tactical.sqf) | F12 malformed/range requests, UID cooldown, replacement/cap, expiry/deleted authors and phase cleanup. Idle server and a living conscious WEST human on the map. |
| [droneControl.sqf](../tests/droneControl.sqf) | Actual drone control lifecycle with temporary UAVs. Idle hosted editor, living player, normal player camera and no active control session. Death/respawn and dedicated dispatch require separate checks. |
| [friendlyBulwark.sqf](../tests/friendlyBulwark.sqf) | Actual friendly controller, relocation, patrol/camp, held-state and takeover/static exclusions. Idle hosted editor, living player and LAMBS. Navigation/HC/insertion require separate checks. |
| [supplyCache.sqf](../tests/supplyCache.sqf) | F15 manifests, scheduling, real workers/cargo, lifecycle and ordinary-loot cleanup separation. Idle disposable server/editor, living WEST human, valid nearby site and no supply worker. Deletes nearby loose loot. |
| [supplyDelivery.sqf](../tests/supplyDelivery.sqf) | Real cache delivery/parachute/cleanup with controlled spawn/transit fixtures. Idle disposable server/editor, WEST human, no caches and two clear LZs. Navigation/wind/natural landing/JIP remain separate checks. |
| [engineeringCache.sqf](../tests/engineeringCache.sqf) | Random engineering stock/caps, typed cargo/policy, independent rolls, both-family cleanup and site-publication races. Idle disposable server/editor, living WEST human, two safe separated sites and no cache workers. |
| [thunderstorm.sqf](../tests/thunderstorm.sqf) | Actual storm singleton, saved state, strike guards and lifecycle/extraction cleanup. Changes weather and temporarily stubs native lightning. Idle disposable server/editor without a running mission loop/storm. Run Specials On and Off; dedicated effects/damage/JIP need separate acceptance. |
| [officerHunt.sqf](../tests/officerHunt.sqf) | Real officer producer, exclusivity/settings, reinforcement cap, death during a capacity wait, handoff/cooldown and expiry. Idle disposable server/editor with living human, LAMBS, valid site and no hostiles/FOB/officer event. Temporarily overrides site selector/settings. Run Specials On and Off. |
| [debugShop.sqf](../tests/debugShop.sqf) | Actual debug action: unknown ID, hostile sides, friendly/caller survival and cooldown. Idle disposable server/editor with no hostiles and a living host/admin within 10 metres of the Bulwark. Creates/removes temporary actors and restores cooldown state. UI and normal-client/spoofed RPC rejection require separate acceptance. |
| [debugForceWave.sqf](../tests/debugForceWave.sqf) | Actual forced-wave cleanup, waiting/orphan capacity cancellation, tagged hostile vehicle deletion, friendly preservation and exact next-wave/type scoping. Initialized idle disposable server/editor without active caches/objectives/spawn work/hostiles. Does not run the full mission loop; all-special transitions remain separate acceptance. |

Typical invocation from a server-side debug console, after satisfying the script's preconditions:

~~~sqf
[] execVM "tests\spawnCapacity.sqf";
~~~

Use the appropriate filename and execution locality for the desired test. Inspect the RPT output and any failure array named in that script. readyVote.sqf, tactical.sqf, supplyCache.sqf, engineeringCache.sqf, supplyDelivery.sqf, thunderstorm.sqf, officerHunt.sqf, debugShop.sqf and debugForceWave.sqf report local failure lists to RPT rather than exposing persistent failure globals. None of these fifteen scripts has been executed in Arma during the work documented here. They temporarily change test state, so do not run the idle-session harnesses in a live multiplayer match. The spawn-capacity harness also covers deadline expiry before admission, during capacity waiting and after engine creation.

The current folder already has the Altis world suffix: dynamicBulwarks.Altis. Use a separate disposable mission copy for destructive/idle-session testing; keep the authoritative source in place and do not silently package it. Supply the required mods and verify mission editor dependencies.

## Multiplayer acceptance checks

1. Two clients: concurrent shop/bank requests, the final respawn ticket, ticket purchases after depletion and corpse-bound delays.
2. Team extraction: one member repeatedly entering must not accumulate credit; all living survivors must be present together, including unconscious survivors.
3. Combined specials: suicide + transport near defenses; mortar + Grad + paradrop; destroy a FOB while unrelated enemies remain.
4. Capacity: fill the ordinary threshold, admit special troops, hold a transport at capacity over 60 seconds, kill enemies to release slots and extract while requests wait.
5. AI: inspect creep versus rush, approach/leave the 10/25 metre CQB band, repeat object pickup/place and destroy an aircraft before/during insertion.
6. Ownership: Zeus remote-control an enemy, then release it; transfer an AI group to a headless client and back. Confirm no duplicate movement tasks, lost cleanup or missing score events.
7. Parameters: specials Off, vehicles Never/start-wave, unlimited waves, both faction modes and updated numeric multipliers.
8. F01: strict majority with join/leave/incapacitation/respawn, minimum preparation, one final warning, stale phase and spoofed caller rejection. See [READY_VOTE.md](READY_VOTE.md).
9. F09: later-wave selection, two-intervening-wave cooldown, singleton setup, capacity-wait cache destruction and surviving-defender handoff.
10. F12: all four ping kinds, cooldown/cap/expiry, author death/disconnect, JIP snapshots, HUD recovery, English/Polish labels and UI scales. See [TACTICAL_STATUS.md](TACTICAL_STATUS.md).
11. F15: both families, VTOL approach/release, natural parachute descent/wind, safe LZ/drift checks, loss/timeouts and in-flight cancellation/asset cleanup, inbound/JIP labels, simultaneous inventory transfers, preparation/ready-skip cleanup, native tools and placed-mine survival/friendly damage. See [SUPPLY_CACHES.md](SUPPLY_CACHES.md).

## RPT and late-wave measurements

Locate the RPT for the actual server instance and test time, using its launch/profile configuration. The default client log directory is not sufficient evidence for a remote or custom-profile dedicated server.

Search for Error in expression, Error position, Undefined variable, Type, missing function/class messages and script stack locations. Preserve surrounding lines and identify the exact mission build/mod set and wave. Separate script errors from missing-content/config warnings.

For a later-wave performance session, record a time series rather than one FPS reading:

- Wave, player count, selected waveTypes and server diag_fps/diag_fpsMin.
- Living EAST/RESISTANCE count, BW_ENEMY_LIMIT and BW_INFANTRY_REMAINING.
- Waiting/granted BW_SPAWN_QUEUE entries and unfinished BW_SPAWN_JOBS.
- Active FOB caches, transport phases, wave duration and any errors.
- Sampling interval, server hardware/mod versions and headless-client arrangement.

Sample during ordinary combat, maximum stacking, capacity waits and intermission. Test several waves in the late-game range; record whether backlog drains and whether FPS recovers after cleanup. No benchmark has established that 120 AI is suitable for every server.

## Safe change checklist

- Capture originating wave IDs in delayed scripts and bound waits by cancellation/survival/time.
- Keep finite spawn producers registered until their work is finished.
- Route active hostile creation through spawnLimited and handle empty returns.
- Respect group locality/player ownership; preserve group identity when using taskReset.
- Stop previous task handles before assigning a new long-running behavior.
- Keep cash/ticket decisions server-side and validate the caller.
- Update current guides and fix records; mark historical findings resolved instead of silently rewriting their original evidence.
- Run static validation, document unrun engine tests and honor the no-PBO instruction.
