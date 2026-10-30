# Enemy AI behavior review

Historical findings from the Altis.bulwarkFixed review, followed by the implemented resolutions below. Original line numbers describe the pre-fix source. Findings were static code findings, not observed RPT errors. No PBO was built.

## High priority

1. bulwark/solidobject.sqf:15 — During a suicide wave, ANY living EAST unit near a placed object is killed and the object deleted. This bypasses the new bw_suicideBomber tag and affects ordinary transport/vehicle troops from combined specials. Both build/functions/fn_drop.sqf:65 and fn_place.sqf:69 actively launch this script. Restrict detonation to tagged bombers.
2. bulwark/solidobject.sqf:2–13 — Loop checks the initial _isHeld forever but refreshes a different variable, _isPlaced. Picking the object up does not stop the loop. Placing/dropping it again starts another loop; multiple controllers can accumulate for one object. Use a single per-object controller and refresh the variable used by its condition.
3. bulwark/solidobject.sqf:20–30 — Obstacle avoidance issues doStop, CARELESS, UP and forceSpeed 6 without restoring these overrides. It repeats every two seconds for nearby enemies and competes with assault/CQB tasks. This can leave ordinary infantry with inappropriate behavior/speed. Use temporary, bounded avoidance with restoration and preserve special task ownership.
4. hostiles/clearStuck.sqf:18–25 — Sixty seconds of low displacement is treated as a stuck unit even when a transport is deliberately waiting for the new capacity gateway. The vehicle can be destroyed if distant/unknown to players. There is no exclusion for capacity waiting or scripted transport phases. Exempt those states and verify failure to progress toward an actual movement order before removing units.
5. hostiles/KillTeam.sqf:287,290,366 and hostiles/moveHosToPlayer.sqf:5–19 — Dropped troops receive BIS_fnc_stalk, while the periodic controller discovers their missing killPointMulti, registers them and launches LAMBS rush. Both systems can own movement orders for the same group; later taskReset does not explicitly terminate the BIS stalk script. Assign scoring immediately and use one movement controller for the group.
6. hostiles/moveHosToPlayer.sqf:24–29 — Main eligibility does not exclude players or player-led groups; the earlier registration pass excludes individual players but can still queue their AI subordinates' group. Zeus-controlled enemy/player-led groups can have their orders replaced. Exclude player-containing groups and respect group locality. Current server-only execution also does not establish that a group transferred to a headless client is local.

## Other confirmed issues

7. hostiles/KillTeam.sqf:218 — The progressive landing approach loop only checks distance and helicopter survival. Unlike the adjacent waits, it lacks wave cancellation and a timeout. A living helicopter that never reaches the ramp endpoint can leave this child script running indefinitely.
8. hostiles/spawnSquad.sqf:262,281 — Some soldiers are marked creep, but their group always receives taskRush; the periodic controller reads the group's bw_aiMode, not the individual creep tag. Choose one movement mode per group and apply its corresponding task.
9. hostiles/spawnSquad.sqf:38–44 — The wave 20–24 condition occurs twice. Skill 0.2 is immediately overwritten by 0.4. Decide the intended value and remove the duplicate branch.
10. hostiles/spawnSquad.sqf:119,155–157 and hostiles/moveHosToPlayer.sqf:33–34 — Solo suicide bombers receive LAMBS rush with danger AI enabled, then periodic direct movement/CARELESS orders. Give bombers a dedicated controller instead of two concurrent movement systems.
11. hostiles/KillTeam.sqf:167,289–290,363 — Random-player targeting can use empty lists; the initial waypoint also includes headless clients and dead players. Filter living conscious humans and use the existing spawn-anchor fallback when none exist.
12. hostiles/moveHosToPlayer.sqf:37–44 — CQB entry and exit both use the same 10 m boundary. Small distance changes can reset/restart tasks every controller poll. Use separate entry/exit thresholds and avoid restarting a task until a meaningful state change.

## Validation boundaries

The previous fixes did not fully address the active object-avoidance script or helicopter troop controller conflicts. The capacity-wait/anti-stuck conflict is an interaction introduced by streaming reinforcements. LAMBS function signatures and headless-client behavior require checking against the installed mod version; no claim is made that every object-form LAMBS call is invalid. Dormant hostiles/solidObjects.sqf and legacy spawners were not treated as active defects.

Recommended engine checks after fixes: combined suicide + transport wave near placed defenses; repeated pickup/place of one defense; transport held at full capacity longer than 60 seconds; helicopter landing failure/extraction; Zeus-controlled enemy group; HC ownership transfer; movement across CQB boundary; waves 19/20/24/25 skill values.

## Implemented resolutions

- Findings 1–3: solidobject.sqf is now a singleton server watcher. It pauses while held and only triggers tagged bombers. Removed the ordinary-infantry movement overrides entirely; engine/LAMBS pathfinding retains control.
- Finding 4: anti-stuck cleanup only considers local on-foot infantry under managed rush/creep, with an outstanding MOVE/FOLLOW order. It excludes player/Zeus/scripted groups and combat, requires a stable distant destination and two consecutive 60-second stall samples, and never destroys vehicles. Scripted transports retain their own cleanup. HC-owned infantry is conservatively skipped by this server cleanup.
- Findings 5, 6, 8, 10 and 12: a single owner-local controller tracks LAMBS task handles. It stops the previous task before a mode change, gives bombers dedicated movement, honors group-level creep selection and uses CQB entry <10 m / exit >=25 m. A watchdog stops tasks on ownership/player-control changes, scripted handoff, phase change or expired server lease. Server dispatch targets the current group owner; player-containing and Zeus-controlled groups are excluded.
- Helicopter troops are scored/protected immediately and released to the same controller after insertion. BIS stalk was removed. Truck drivers now follow their transport waypoint without a competing creep loop.
- Findings 7 and 11: helicopter approach loop now has a timeout and wave cancellation; its initial target uses spawnAnchor and empty-player random choices were removed with stalk logic.
- Finding 9: the duplicate 0.2 assignment was removed; waves 20–24 retain their previous effective skill of 0.4.
- Additional confirmed issue: default LAMBS taskReset creates a replacement group. Active callers now use its soft-reset option to preserve references; managed task transitions also explicitly terminate old script handles.

## Validation after edits

Static lexical/config/reference and targeted integration checks pass. Added tests/aiBehaviour.sqf to exercise actual controller transitions, task cancellation, group identity, scripted/Zeus exclusions, singleton defense watching, held-object pause, ordinary enemy survival and tagged-bomber triggering in an idle hosted editor session. It has NOT been run in Arma. Multiplayer ownership transfer, navigation and the anti-stuck timing still need in-engine checks.

Upstream API references checked:
- https://github.com/nk3nny/LambsDanger/blob/master/addons/wp/functions/fnc_taskReset.sqf
- https://github.com/nk3nny/LambsDanger/blob/master/addons/wp/functions/fnc_taskRush.sqf
- https://github.com/nk3nny/LambsDanger/blob/master/addons/wp/functions/fnc_taskCreep.sqf
- https://github.com/nk3nny/LambsDanger/blob/master/addons/wp/functions/fnc_taskCQB.sqf
- https://community.bohemia.net/wiki/remoteControlled (requires Arma 3 2.14+)

Installed LAMBS compatibility remains an engine-test requirement.
