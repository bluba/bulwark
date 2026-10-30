# Special-wave review

## Wave-six vehicle investigation — 2026-10-30

There is no unconditional wave-six special in the inspected source. With the default vehicle threshold of 5 and normal random mode, wave 6 independently rolls:

| Producer | Chance | Count before fix, one human | Count after fix, one human |
| --- | --- | --- | --- |
| Ordinary armed cars | 36% | 2 | 2 |
| Ordinary attack helicopters | 21% | 1 | 1 |
| Helicopter troop transports | 37% | 2 | 1 |
| Truck troop transports | 36% | 2 | 1 |
| Heavy armour | Ineligible until wave 10 with default settings | 0 | 0 |

These rolls are independent: about 79.6% of normal wave-six plans select at least one automatic vehicle producer, before accounting for a special. A 41% special roll can additionally select one of six beginner effects, including convoy or paradrop. A wave-six convoy previously created three trucks through an inclusive zero-based loop; it now creates two. Multiple categories can still stack. With one human, the maximum selected vehicles across those automatic paths plus convoy falls from ten to seven; not every plan selects every path, and missing content/spawn cancellation can reduce actual creation.

**Bugs fixed:** the two transport loops began at zero and used fractional random upper bounds, giving two transports even when the wave divisor was zero. Counts are now explicit positive integers and loops run from one through that count. The convoy loop also uses an explicit integer count rather than spawning an extra vehicle. Vehicle and ordinary infantry scaling now use the same connected-human roster helper as other mission systems, instead of `playersNumber`, which can count lobby/AI slots in other configurations. This mission currently sets `disabledAI=1`, so AI-slot inflation alone does not explain default play; see [Bohemia's command contract](https://community.bistudio.com/wiki/playersNumber).

Added `Bulwark vehicles:` RPT records with the wave number, category and selected count; regular categories also report human count. These record requested plans, not successful asset creation. Probability formulas, stacking rules, content catalogues, vehicle-start/Never gating and debug-forced-wave behavior remain as before. Specials Off still does not disable ordinary automatic vehicles.

Source-level lexical and count-bound checks passed. No Arma simulation was run. Reproduce with one and four clients, review wave 5/6/9/10 counts in the RPT, test Specials Off and Vehicles Never, and confirm debug-forced waves still suppress automatic additions. If vehicles remain excessive, a shared per-wave vehicle budget would be a separate balance change.

Baseline: Altis.bulwarkFixed. Code inspection and static validation completed; no Arma engine test was run.

## Confirmed bugs fixed

- Wave lifetime: artillery, Grad, mortar, civilian, suicide, drone and aircraft jobs carry their originating wave and stop on intermission/extraction. Tracked artillery projectiles are removed at intermission.
- Stacked mortars: each instance has private vehicle/crew/group state and fires through the mortar object.
- Late-wave selection: the second modifier after wave 20 now reaches the dispatch list. Disabling specials clears the complete plan; the vehicle start/Never setting filters vehicle specials.
- Night stacking: repeated night modifiers no longer overwrite the saved time.
- FOB completion: a living reinforcement cache prevents wave completion; destroying it stops reinforcements and releases surviving defenders to attack.
- Drones: empty/dead group lists and empty target lists are checked; firing is issued through the UAV instead of its pilot. The limit is 15 rather than 16, and vehicles/crew are tracked for cleanup.
- Civilians: building positions are collected into a finite pool, eliminating endless retries where no usable building exists. Their script no longer mutates the shared loot-building list.
- Suicide waves: proximity detonation, audio and movement select tagged bombers rather than ordinary enemies from stacked specials.
- Aircraft: transit waits are bounded and cancellation-aware. Strike count is chosen once; child jobs retain the original wave.
- Infantry groups: reuse the group returned by the squad spawner instead of transferring everyone into another group and leaving an empty group behind. Failed solo/group spawns clean up empty groups.

Primary files: bulwark/functions/fn_startWave.sqf, bulwark/functions/fn_endWave.sqf, bulwark/missionLoop.sqf, hostiles/spawnSquad.sqf, hostiles/droneFire.sqf, hostiles/civWave.sqf, hostiles/suicideWave.sqf, hostiles/suicideAudio.sqf, hostiles/specMortar.sqf, hostiles/airStrike.sqf.

## Remaining selection and balance concerns

1. **Resolved in source (F09): strongpoints disappeared after wave 9.** Encampment is now also in the later-wave primary pool. Eligibility starts at wave 7, excludes duplicate/planned/live/pending FOBs, and requires two intervening waves by default. Setup reserves a singleton slot and cooldown starts only after a live cache is created. Selection still uses the normal special roll; it is not guaranteed. New variants remain deferred; in-engine checks are pending. See FIXES.md.
2. **Resolved: enemy count previously grew quadratically.** In hostiles/createWave.sqf, infantry count is floor(wave × multiplier × max(1, floor(westPlayers × teamMultiplier)) × max(1, wave/10)). With 25 players, multiplier 2 and teamMultiplier 0.5, wave 30 requests 2,160 infantry before additional units. This poses a substantial server-performance risk. Implemented a linear budget plus a shared active limit of min(120, 30 + 4 × human players), with 20% reserved for specials; see FIXES.md. The preceding formula describes the old behavior.
3. **Resolved: duplicate weather/time picks.** Fog, night and thunderstorm are excluded from subsequent draws once selected. Combat specials can still repeat. Vehicle eligibility is checked before drawing so replacements are not discarded by the vehicle setting. Up to four selected effects can stack after wave 16, with separate automatic vehicles.
4. **Disabling specials does not disable ordinary vehicles.** Automatic vehicle/transport spawning in createWave is separate from the special selector. Use the vehicle Never option as well when testing infantry-only play.

## Required gameplay checks

On a dedicated server with the installed PSZ/CUP/RHS/LAMBS versions:
- Force every special individually, then stack mortar + Grad + paradrop and suicide + transports.
- End the wave or extract during aircraft transit, artillery firing and civilian spawning; verify cleanup and no delayed attacks in build phase.
- Kill all drone crews, disconnect/kill all available targets, and confirm the drone loop stays error-free; verify the antimine UAV actually fires its installed weapon.
- Spawn civilians around buildings with no interior positions.
- Destroy a FOB cache while defenders remain, and kill defenders while leaving its cache intact.
- Exercise specials Off and vehicle start/Never settings.
- Inspect the server RPT for script errors and measure AI load in later waves.

Static checks verify lexical structure, function/script references and lobby parameters. They do not establish SQF compilation, mod-class compatibility, locality correctness or combat behavior.

## Follow-up fixes — 2026-10-29

Review findings 2, 3 and 4 are addressed in source:

- Surviving mortar crew lose both `bw_stationary` and `NonCQB` after mortar loss, receive rush mode and are handed to the infantry controller on their group owner. Wave cancellation still deletes the mortar and crew.
- `spawnLimited` rechecks wave and guard survival after engine creation returns. Cancelled groups, units or vehicle/crew results are deleted before the reservation is released and the normal empty result is returned. Truck and both helicopter insertion branches also reject empty/cancelled cargo before boarding.
- Paradrop capacity waits no longer authorize a drop at an arbitrary later aircraft position. A newly allocated pending troop is hidden, inactive and protected while the aircraft makes a return pass, bounded by 120 seconds. Actual deployment rechecks the live aircraft, originating wave and 250-metre drop-zone radius without suspension. Failed transit/cancellation removes the pending troop and ends the batch; previously dropped troops remain managed normally.

Finding 1 remains open: mortar-fired shells are not registered in `BW_WAVE_PROJECTILES` and can remain airborne into preparation. The fixes above do not change artillery projectile handling.

`tests/spawnCapacity.sqf` now includes a valid guarded group and deterministic guard deletion / wave cancellation after real group creation, checking deletion of the entire result and reservation release. It temporarily wraps and restores `BIS_fnc_spawnGroup`; use only the documented idle disposable session. This harness has not been run in Arma.

Additional engine acceptance: destroy a mortar while its gunner is protected and confirm the surviving dismounted gunner attacks; transfer its group to a headless client and repeat. Fill capacity during a paradrop, let the aircraft leave the drop zone, release slots and verify a return pass before deployment. Destroy the carrier, extract or prevent its return during that wait; confirm there is no hidden pending troop, orphaned cargo or leaked queue entry.

Verification performed: string/comment/delimiter checks passed for the five changed gameplay SQF files and `tests/spawnCapacity.sqf`; registration and source-file checks passed for `spawnLimited`, `waveActive`, `controlEnemyGroup` and `waitForAircraft`. These checks do not compile or execute SQF. No Arma test session was run and no PBO was created.

## Thunderstorm addition — 2026-10-29

[Thunderstorm](THUNDERSTORM.md) adds one weather modifier from wave 5 with heavy rain, ambient lightning and occasional native ground strikes. It uses saved-weather restoration, a wave-bound singleton outside completion jobs, disposable server-owned strike targets and a current-state client/JIP snapshot. Specials Off and Vehicle Never retain their documented behavior. Dedicated visuals/damage locality and weather/JIP acceptance remain pending; `tests/thunderstorm.sqf` is provided but unrun.
