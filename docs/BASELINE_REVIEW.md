# Extracted Bulwark baseline review

Historical review of the unmodified Workshop extraction. Fixes are now applied in the extracted baseline; see [FIXES.md](FIXES.md) for implementation and validation status. Source line numbers below refer to the pre-fix snapshot.

Reviewed: 2026-10-28. Baseline: `Altis.bulwarkFixed`, recovered from Workshop item 2995798737. The older source at the project root is reference material only.

Scope: static inspection of the active mission loop, new objectives, enemy spawning, revival, economy, building purchases, loot, configuration and supports. No scenario source was changed. No Arma executable/compiler was available for an in-engine run; findings describe source-level defects and reproduction steps, not completed gameplay tests. P1 means a core feature can fail, lose inventory or bypass payment; P2 means incorrect behaviour, configuration, reliability or performance.

28 findings: 11 P1 and 17 P2. Some findings group the same defect repeated across files.

## 01. [P1] Extraction counts visits instead of players

Source: [extract.sqf:43](C:/Users/glask/Downloads/glask-altis_pl_vs_ru-490445bafdcd/glask-altis_pl_vs_ru-490445bafdcd/Altis.bulwarkFixed/extract.sqf:43).

pCountAtZone is initialized outside the polling loop and incremented every ten seconds. With four connected players, the same one player remaining inside for four polls satisfies the four-player requirement. Dead, unconscious and headless clients are also not explicitly filtered.

Recommended fix and verification: Recompute the eligible human roster and the number currently inside on each poll. Explicitly decide whether unconscious/dead players must be recovered. Test four players with only one entering, leaving and re-entering.

## 02. [P1] Extraction does not finish the mission during combat

Source: [missionLoop.sqf:54](C:/Users/glask/Downloads/glask-altis_pl_vs_ru-490445bafdcd/glask-altis_pl_vs_ru-490445bafdcd/Altis.bulwarkFixed/missionLoop.sqf:54).

missionExtract is checked before starting a wave and after its hostile-monitoring loop, but not inside that loop. Reaching extraction while enemies remain does not trigger End3; players can still lose before the wave ends.

Recommended fix and verification: Check extraction in the combat monitor, give success/failure a defined priority, and stop active wave jobs when extraction succeeds. Test extraction with a living enemy left on the map.

## 03. [P1] Enemy FOB has no destruction condition

Source: [hostiles/createEmplacement.sqf:132](C:/Users/glask/Downloads/glask-altis_pl_vs_ru-490445bafdcd/glask-altis_pl_vs_ru-490445bafdcd/Altis.bulwarkFixed/hostiles/createEmplacement.sqf:132).

Buildings are created without retaining a destruction target. Reinforcements depend only on wave number and buildPhase. Destroying tents/bunkers or killing the garrison does not stop reinforcements; the spawn job stops only when the wave/build state changes. This contradicts the advertised destroy-the-FOB mechanic.

Recommended fix and verification: Retain an explicit destructible objective, track its state and stop spawning when destroyed. Clean up its buildings and groups. Test destroying the objective while other wave enemies remain alive.

## 04. [P1] Damage protection result is discarded

Source: [initPlayerLocal.sqf:168](C:/Users/glask/Downloads/glask-altis_pl_vs_ru-490445bafdcd/glask-altis_pl_vs_ru-490445bafdcd/Altis.bulwarkFixed/initPlayerLocal.sqf:168).

The protection condition evaluates a block returning 0, then unconditionally calls BIS_fnc_reviveEhHandleDamage. The handler therefore returns the latter result. The same defect is present in onPlayerRespawn.sqf:27. Friendly-fire suppression, fall protection and revival immunity are not enforced by this branch.

Recommended fix and verification: Use a single shared damage handler with an early return for protected damage. Preserve existing selection damage where appropriate, because HandleDamage returns absolute damage. Test friendly fire, falling, incapacitation and revival separately.

## 05. [P1] Medikit conversion destroys inventory

Source: [bulwark/fakToMedKit.sqf:20](C:/Users/glask/Downloads/glask-altis_pl_vs_ru-490445bafdcd/glask-altis_pl_vs_ru-490445bafdcd/Altis.bulwarkFixed/bulwark/fakToMedKit.sqf:20).

Array subtraction removes every FirstAidKit entry, not just ten. A box with twenty kits receives only one Medikit. In the nearby Box_NATO_Support_F branch, the inner loop shadows the container with an item string and executes _x addItemCargoGlobal [_x,1]. This raises a type error after cargo has already been cleared, losing non-FAK items. The Bulwark branch also removes all excess FAKs.

Recommended fix and verification: Keep the container in its own variable, remove exactly ten kits per conversion and preserve other cargo. Test ten, twenty and twenty-five kits alongside unrelated items in both supported containers. UI text also needs to agree with the chosen cost; it currently says fifteen.

## 06. [P1] Bank transfers and purchases are not atomic

Source: [score/functions/fn_depositPointsToPointBank.sqf:15](C:/Users/glask/Downloads/glask-altis_pl_vs_ru-490445bafdcd/glask-altis_pl_vs_ru-490445bafdcd/Altis.bulwarkFixed/score/functions/fn_depositPointsToPointBank.sqf:15).

Deposits credit the bank before a separately queued debit. Withdrawals debit the bank without validating its current balance on the server. Client-only balance checks cannot prevent two simultaneous withdrawals or repeated deposits against stale balances. Building/support purchases similarly grant their result without waiting for a successful debit.

Recommended fix and verification: Validate caller, amount, balance and configured limit on the server. Perform debit and credit/grant together in one non-suspending server transaction. Derive prices from server catalogues. Test two simultaneous withdrawals and rapid repeated purchases.

## 07. [P1] Tickets can be bought with no money

Source: [supports/functions/fn_livesTicket.sqf:15](C:/Users/glask/Downloads/glask-altis_pl_vs_ru-490445bafdcd/glask-altis_pl_vs_ru-490445bafdcd/Altis.bulwarkFixed/supports/functions/fn_livesTicket.sqf:15).

The server grants tickets unconditionally before calling the spending function. purchaseNew.sqf does not check funds in the ticket category. When funds are insufficient the spending function silently does nothing, leaving the tickets granted for free.

Recommended fix and verification: Validate a server-defined ticket SKU and balance, debit first and grant only on success within the same transaction. Test a normal menu purchase with zero points.

## 08. [P1] Last ticket blocks the respawn it should pay for

Source: [onPlayerKilled.sqf:5](C:/Users/glask/Downloads/glask-altis_pl_vs_ru-490445bafdcd/glask-altis_pl_vs_ru-490445bafdcd/Altis.bulwarkFixed/onPlayerKilled.sqf:5).

The death script subtracts a ticket and disables respawn when the resulting count is zero. Starting with one ticket therefore consumes it and gives the dead player a 99999-second wait. The configured RESPAWN_TIME is also overwritten with 0 at wave end and not restored for a later wave with tickets. Buying tickets does not explicitly re-enable a previously disabled timer.

Recommended fix and verification: Centralize ticket reservation and respawn timing on the server. Preserve the configured delay separately from temporary phase state. Test the last ticket, buying tickets after depletion, and the next wave after free build-phase respawns. Also test concurrent deaths on a dedicated server.

## 09. [P1] Friendly ammunition delivery spawns enemy soldiers

Source: [supports/functions/fn_ammoRequest.sqf:59](C:/Users/glask/Downloads/glask-altis_pl_vs_ru-490445bafdcd/glask-altis_pl_vs_ru-490445bafdcd/Altis.bulwarkFixed/supports/functions/fn_ammoRequest.sqf:59).

The supply-drop function creates a six-man EAST group at the aircraft spawn position and never uses it for the delivery. This adds enemies kilometres away and all EAST units are counted for wave completion. They may delay the wave until killed or removed by another script.

Recommended fix and verification: Remove the unrelated infantry spawn. Test the EAST unit count before and after a friendly delivery, including destruction of the delivery aircraft.

## 10. [P1] Friendly paratrooper support contains invalid syntax

Source: [supports/functions/fn_paraTroop.sqf:80](C:/Users/glask/Downloads/glask-altis_pl_vs_ru-490445bafdcd/glask-altis_pl_vs_ru-490445bafdcd/Altis.bulwarkFixed/supports/functions/fn_paraTroop.sqf:80).

removeAllWeapons _self: ends with a colon rather than a semicolon inside the Killed handler. This is a syntax defect in a CfgFunctions-registered support script; the affected support cannot be considered reliable until it compiles.

Recommended fix and verification: Correct the statement terminator and compile the function in Arma. Then call the support and kill a landed ally to exercise the embedded handler.

## 11. [P1] Enemy mortar passes an array where an object is required

Source: [hostiles/specMortar.sqf:24](C:/Users/glask/Downloads/glask-altis_pl_vs_ru-490445bafdcd/glask-altis_pl_vs_ru-490445bafdcd/Altis.bulwarkFixed/hostiles/specMortar.sqf:24).

specMortar is the complete [vehicle, crew, group] return value of BIS_fnc_spawnVehicle. doArtilleryFire expects an object, so the special-wave mortar fire call has a type error. Global mortarGunner/specMortar also make concurrent instances share state.

Recommended fix and verification: Unpack the spawn return into private variables and issue fire on the mortar object. Test two mortar specials together and verify both fire independently.

## 12. [P2] Bonus objective runs in the wrong phase

Source: [bulwark/defendLocationBonus.sqf:25](C:/Users/glask/Downloads/glask-altis_pl_vs_ru-490445bafdcd/glask-altis_pl_vs_ru-490445bafdcd/Altis.bulwarkFixed/bulwark/defendLocationBonus.sqf:25).

The objective starts from fn_endWave.sqf:13 and polls only while buildPhase is true. It is removed as combat starts, rather than remaining available during the wave as described. It is launched before buildPhase is set true, which also introduces scheduling dependence at startup.

Recommended fix and verification: Define whether this is a combat or intermission objective, then start and cancel it using that explicit phase and captured wave ID. For the advertised behaviour, create it at wave start and allow completion throughout combat.

## 13. [P2] Special-wave disable setting is ignored

Source: [missionLoop.sqf:11](C:/Users/glask/Downloads/glask-altis_pl_vs_ru-490445bafdcd/glask-altis_pl_vs_ru-490445bafdcd/Altis.bulwarkFixed/missionLoop.sqf:11).

SPECIAL_WAVES is read into _specialWaves but never used to gate the random selection or execution in fn_startWave.sqf. Selecting No still allows specials, including the unconditional additional modifier after wave fifteen.

Recommended fix and verification: Gate the full special selection path, not only one probability branch. Test multiple waves with SPECIAL_WAVES=0.

## 14. [P2] Vehicle start and Never settings are ignored

Source: [hostiles/createWave.sqf:9](C:/Users/glask/Downloads/glask-altis_pl_vs_ru-490445bafdcd/glask-altis_pl_vs_ru-490445bafdcd/Altis.bulwarkFixed/hostiles/createWave.sqf:9).

ARMOUR_START_WAVE is read but unused. Vehicles and transports use hard-coded thresholds such as attkWave > 7 or > 10; choosing Never (9999) does not disable them.

Recommended fix and verification: Define which vehicle families the option controls and gate their spawn paths consistently, including convoy and transport specials if intended. Test Never and a late start threshold.

## 15. [P2] Several lobby parameters violate the numeric parameter contract

Source: [description.ext:342](C:/Users/glask/Downloads/glask-altis_pl_vs_ru-490445bafdcd/glask-altis_pl_vs_ru-490445bafdcd/Altis.bulwarkFixed/description.ext:342).

MAX_WAVES contains the string infinite; RANDOM_WEAPONS contains true/false strings and defaults to No, which is not even one of those values. HUD_POINT_HITMARKERS has a string default. HOSTILE_MULTIPLIER includes fractional 0.5. Code expects numeric results and compares RANDOM_WEAPONS to 1.

Recommended fix and verification: Use integer values throughout: e.g. -1 for unlimited, 0/1 for booleans and scaled integer multipliers. Test every affected lobby option and log the actual selected numeric value.

## 16. [P2] Medikit conversion continuously consumes scheduler time

Source: [bulwark/fakToMedKit.sqf:11](C:/Users/glask/Downloads/glask-altis_pl_vs_ru-490445bafdcd/glask-altis_pl_vs_ru-490445bafdcd/Altis.bulwarkFixed/bulwark/fakToMedKit.sqf:11).

The server starts an unconditional while true loop that scans players, nearby supplies and Bulwark cargo without sleep or a state/event wait. Arma can time-slice scheduled scripts, but this job continually uses its available scheduled execution budget.

Recommended fix and verification: Use container/inventory events or a bounded polling interval. Measure server script load and responsiveness with many players and nearby supplies.

## 17. [P2] Squad size and enemy counter disagree

Source: [hostiles/spawnSquad.sqf:153](C:/Users/glask/Downloads/glask-altis_pl_vs_ru-490445bafdcd/glask-altis_pl_vs_ru-490445bafdcd/Altis.bulwarkFixed/hostiles/spawnSquad.sqf:153).

_teamCount = random 5 produces fractions and values below one. The integer for loop creates zero to four classes, while _spawnedUnits increases by the original fraction. The desired enemy total is therefore not the number spawned, and the advertised one-to-five-man squads are not generated by this branch.

Recommended fix and verification: Choose an integer size from one to five, cap it to the remaining budget, and increment by actual successfully spawned units. Test requested totals of ten, eleven and a large wave.

## 18. [P2] Purchased ally range reads the wrong row and field

Source: [bulwark/purchaseNew.sqf:26](C:/Users/glask/Downloads/glask-altis_pl_vs_ru-490445bafdcd/glask-altis_pl_vs_ru-490445bafdcd/Altis.bulwarkFixed/bulwark/purchaseNew.sqf:26).

Most properties use _itemIndex, but _vechAiRange uses the category-local UI index _index and field 7. Field 7 is the catalogue ID; the range is field 8. Allies therefore receive an unrelated item ID instead of their configured range.

Recommended fix and verification: Read field 8 from the selected catalogue entry, preferably unpacking that entry once. Test allies in several categories and log the supplied AI range.

## 19. [P2] Mind control joins the previous list before adding the current unit

Source: [supports/functions/fn_mindConGas.sqf:35](C:/Users/glask/Downloads/glask-altis_pl_vs_ru-490445bafdcd/glask-altis_pl_vs_ru-490445bafdcd/Altis.bulwarkFixed/supports/functions/fn_mindConGas.sqf:35).

_aiToJoin join _player executes before _aiToJoin pushBack _x. The final eligible enemy in each pass is never joined by that pass; with only one enemy, every pass joins an empty array. The enemy is nevertheless recorded for end-of-wave death.

Recommended fix and verification: Build the full eligible list first, then join it once and record only successfully converted units. Test one enemy and several enemies at the edge of the gas radius.

## 20. [P2] Grad directions are deterministic and arguments are unpacked incorrectly

Source: [bulwark/functions/fn_startWave.sqf:253](C:/Users/glask/Downloads/glask-altis_pl_vs_ru-490445bafdcd/glask-altis_pl_vs_ru-490445bafdcd/Altis.bulwarkFixed/bulwark/functions/fn_startWave.sqf:253).

floor(random 1) always yields zero. In the spawned salvo, separate params calls each read argument zero, so _dir2 becomes the first direction instead of the second. The intended directional variety is absent.

Recommended fix and verification: Choose explicit direction values and unpack both arguments in one params statement. Inspect projectile spawn positions and velocities for all intended directions.

## 21. [P2] Artillery survives intermission and shares its wave token

Source: [bulwark/functions/fn_startWave.sqf:234](C:/Users/glask/Downloads/glask-altis_pl_vs_ru-490445bafdcd/glask-altis_pl_vs_ru-490445bafdcd/Altis.bulwarkFixed/bulwark/functions/fn_startWave.sqf:234).

The artillery loop stops only when attkWave changes, so it continues during the build phase. localWave is global and is also assigned by Grad jobs. A later job can overwrite the token of an older loop; delayed Grad launches are not cancelled when the originating wave ends.

Recommended fix and verification: Capture a private wave ID at launch, stop when buildPhase or mission end changes, and re-check after sleeps. Test consecutive artillery/Grad waves and a short wave followed by a long intermission.

## 22. [P2] Second late-game modifier is selected but never executed

Source: [bulwark/functions/fn_startWave.sqf:138](C:/Users/glask/Downloads/glask-altis_pl_vs_ru-490445bafdcd/glask-altis_pl_vs_ru-490445bafdcd/Altis.bulwarkFixed/bulwark/functions/fn_startWave.sqf:138).

After wave twenty, the second modifier is stored in _secondModifier, but execution only iterates waveTypes. This variable is not added to waveTypes, so the successful probability roll has no effect.

Recommended fix and verification: Append the selected modifier to the execution list, with explicit rules for duplicate specials. Test forced successful rolls after wave twenty.

## 23. [P2] Concurrent enemy spawners share side and class lists

Source: [hostiles/createEmplacement.sqf:19](C:/Users/glask/Downloads/glask-altis_pl_vs_ru-490445bafdcd/glask-altis_pl_vs_ru-490445bafdcd/Altis.bulwarkFixed/hostiles/createEmplacement.sqf:19).

opforSide and unitClasses are global across the FOB, mortar, vehicle and squad scripts. These scripts run concurrently; the FOB also reads unitClasses again for later reinforcements. A normal infantry spawn can change the FOB's future reinforcement tier, and another script can change the chosen side. FOB buildings use opforSide before this script sets it.

Recommended fix and verification: Use private per-instance side/class variables and pass them as parameters to child jobs. Test a FOB plus defector and convoy modifiers while recording faction and class selections.

## 24. [P2] Aircraft and unit creation waits have no cancellation or deadline

Source: [hostiles/airStrike.sqf:59](C:/Users/glask/Downloads/glask-altis_pl_vs_ru-490445bafdcd/glask-altis_pl_vs_ru-490445bafdcd/Altis.bulwarkFixed/hostiles/airStrike.sqf:59).

Distance-only waitUntil expressions do not re-check aircraft survival, target validity or the originating wave. ParaDropNew and friendly deliveries have similar waits. spawnSquad waits forever for a null unit after failed creation; fn_startWave waits for that script, preventing the normal mission monitor from running.

Recommended fix and verification: Use deadlines, survival/wave/mission guards and cleanup on every exit. Validate classes before creating units and handle failure explicitly. Test a shot-down aircraft before arrival and a deliberately invalid unit class.

## 25. [P2] Moving to buildings without usable positions can stall the next wave

Source: [loot/spawnLoot.sqf:36](C:/Users/glask/Downloads/glask-altis_pl_vs_ru-490445bafdcd/glask-altis_pl_vs_ru-490445bafdcd/Altis.bulwarkFixed/loot/spawnLoot.sqf:36).

The script only checks that nearby House objects exist, then repeatedly samples buildingPos until a non-nil position appears. If all nearby House objects have no usable building positions, the loop never completes. fn_startWave waits for spawnLoot and does not reach the regular combat/defeat monitor.

Recommended fix and verification: Filter buildings to non-empty positions in advance and exit gracefully when none qualify. Test the mobile Bulwark near industrial structures and terrain with no enterable buildings.

## 26. [P2] Anti-stuck cleanup conflicts with the new FOB defenders

Source: [hostiles/clearStuck.sqf:43](C:/Users/glask/Downloads/glask-altis_pl_vs_ru-490445bafdcd/glask-altis_pl_vs_ru-490445bafdcd/Altis.bulwarkFixed/hostiles/clearStuck.sqf:43).

The cleanup checks whether an EAST unit failed to approach a previous player position by fifteen metres. It does not exempt NonCQB garrison/patrol defenders. A distant, unseen defender doing its assigned job can be deleted after a minute. RESISTANCE units are excluded despite also preventing wave completion.

Recommended fix and verification: Exclude stationary objective defenders and make cleanup aware of current tasks and wave ownership. Handle both hostile factions intentionally. Test an unseen FOB garrison for several minutes and a stuck defector.

## 27. [P2] Map-marker targeting truncates the marker owner's ID

Source: [supports/functions/fn_mortarStrike.sqf:6](C:/Users/glask/Downloads/glask-altis_pl_vs_ru-490445bafdcd/glask-altis_pl_vs_ru-490445bafdcd/Altis.bulwarkFixed/supports/functions/fn_mortarStrike.sqf:6).

The marker parser extracts only one character using select [15,1]. It cannot match a multi-character player ID. The artillery/rocket/HIMARS copies repeat this parsing; they also store the chosen marker in global last, so simultaneous calls can overwrite each other's target between shells.

Recommended fix and verification: Use the communication menu target position or parse the complete marker identifier into private state. Test multiple players and two simultaneous fire requests.

## 28. [P2] Revive failure check uses stale roster and ticket values

Source: [missionLoop.sqf:74](C:/Users/glask/Downloads/glask-altis_pl_vs_ru-490445bafdcd/glask-altis_pl_vs_ru-490445bafdcd/Altis.bulwarkFixed/missionLoop.sqf:74).

After the 45-second grace period, the code recalculates incapacitation using the old _allHPs array and reuses the old _respawnTickets value. It also performs the final check after a further sleep without refreshing either. A disconnect, reconnect or ticket purchase during the grace period can leave the final decision based on obsolete state.

Recommended fix and verification: At the final decision, refresh human players, tickets, revival state and extraction state together. Test disconnect/rejoin and buying tickets during the grace interval.

## Corrections to the earlier-version review

- The original two-second defeat grace period is now 45 seconds, and the Medikit poll interval is five seconds. Do not carry the earlier timing finding forward unchanged. The stale-state defect above remains.
- Player boundary enforcement is commented out in initServer.sqf, so the old high-frequency enforcement loop is not an active performance issue in this baseline.
- mission.sqm no longer declares the old WW2 dependencies.
- The friendly mortar support now uses _newpos correctly; the earlier undefined _pos finding is fixed. The separate enemy-mortar type error remains.
- Extraction, bonus objectives, emplacements and transport scripts do exist now. Their defects are described above rather than treating the features as absent.
- Loot is recalculated around the truck, but spawnLoot first builds a player-based house list and then overwrites it with houses within 100m of the truck. Confirm whether that final truck-only behaviour is intended.

## Additional concerns requiring engine or design confirmation

- CfgRemoteExec in description.ext:54 uses Functions mode=2, allowing all functions rather than enforcing its apparent list. Economic entry points also lack caller ownership checks. Replace it with a complete tested allowlist and server validation; do not simply change the mode without registering the functions the mission and mods actually require.
- AI Hit/Killed handlers return immediately unless isServer. Zeus-created AI or units transferred to a headless client/player can execute their local handlers elsewhere and miss rewards. Verify locality with the actual dedicated-server/Zeus/HC setup, and route scoring to a validated server entry point.
- Several LAMBS tasks are started per unit after putting those units in one group, or started in succession on the same purchased vehicle. Verify the installed LAMBS signatures and group-task cancellation behaviour before changing this integration.
- Respawn/revival operations and truck refuelling should be checked on a dedicated server with the target object owned by a client. Hosted play can hide locality problems.
- checkBulwark.sqf is disabled and contains bulwarlBox (typo). It must not simply be enabled: recreation also resets bank funds and needs proper global object/state synchronization. Movement itself works because the Bulwark is now a truck and several systems choose player/truck positions directly.
- fn_himarsStrike.sqf is present but not registered in supports/Functions.hpp or dispatched by fn_support. Treat it as dormant unfinished code, not an available shop support.
- The heal action advertises/costs 200 points but requires a 500-point balance. The shop lists THS_ZU23_MSV; validate this class against the actual loaded mods before deciding whether it is a typo or a missing dependency.
- Empty-human-player lists, unconscious targets and headless clients are not consistently filtered before selectRandom allPlayers. Test dedicated startup, all-player disconnect, spectator and HC cases.

## Recommended repair order

1. Objective state: extraction membership/completion, bonus phase and destructible FOB lifecycle.
2. Inventory, damage and respawn: safe kit conversion, proper damage returns, ticket reservation and timer restoration.
3. Server transactions: bank, ticket and all item/support purchases; verify concurrent requests.
4. Script errors and lifecycle: paratrooper syntax, enemy mortar type, accidental delivery enemies, cancellable spawn/aircraft/loot jobs.
5. Configuration and AI: respected settings, integer parameters, private spawn state, squad counts and task-aware cleanup.

## Minimum in-game regression matrix

- Dedicated server with two clients, then four clients; join, disconnect and reconnect during combat.
- One player at extraction while others remain away; all required players arrive with enemies still alive.
- Bonus reached during combat; FOB destroyed while unrelated enemies remain alive.
- Ten/twenty/twenty-five FAKs plus unrelated cargo in each conversion container.
- Zero-money ticket purchase, final ticket consumption, tickets bought after depletion and configured delay on the next wave.
- Concurrent bank withdrawals and repeated item/support requests.
- All aircraft destroyed before reaching their destination; invalid/missing mod classes.
- Special waves disabled, vehicles set to Never, unlimited waves and randomized weapons.
- Repeated combined specials over long sessions, plus no enterable buildings around the moving truck.

## Engine documentation consulted

- [HandleDamage return value and locality](https://community.bistudio.com/wiki/Arma_3:_Event_Handlers#HandleDamage).
- [BIS_fnc_spawnVehicle return structure](https://community.bistudio.com/wiki/BIS_fnc_spawnVehicle).
- [doArtilleryFire object argument](https://community.bistudio.com/wiki/doArtilleryFire).
- [Mission parameter integer values](https://community.bistudio.com/wiki/Arma_3_Mission_Parameters).
- [CfgRemoteExec modes](https://community.bistudio.com/wiki/CfgRemoteExec).

