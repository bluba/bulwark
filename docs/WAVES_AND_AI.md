# Waves, spawning and enemy AI

> Regular vehicles now use [ticket planning](VEHICLE_TICKETS.md) by default. The old independent rolls remain available through the compatibility toggle.

## Wave selection

[fn_startWave.sqf](../bulwark/functions/fn_startWave.sqf) rolls a base special with probability random(100) < 35 + wave. The primary pool depends on wave range:

| Waves | Main selection when the base roll passes |
| --- | --- |
| 1–4 | No main special. |
| 5–6 | Beginner pool. |
| 7–9 | Full pool, including encampment. |
| 10–13 | Primary combat pool plus 50% chance of a standard modifier. |
| 14–16 | Primary combat pool plus 75% chance of a standard modifier. |
| 17–20 | Primary combat pool plus 75% / 25% chances of two standard modifiers. |
| 21+ | Primary combat pool plus wave×3% / wave×2% chances (effectively capped at 100%). |

After wave 15, an additional mortar/paradrop/convoy draw occurs independently of the base roll. After wave 20, a failed base roll still has a 25% chance of a standard modifier. The entire plan is cleared when specials are disabled.

Each draw filters fog/night/thunderstorm already selected and vehicle specials forbidden by ARMOUR_START_WAVE (9999 means Never). A draw from an empty eligible pool produces no effect; it never retries indefinitely. Other combat specials may repeat. Defector faction state is established before dispatch, so script order does not choose the mortar faction accidentally.

[Thunderstorm](THUNDERSTORM.md) is in the beginner/full pools and later standard modifiers. It adds full overcast, heavy rain, ambient lightning and occasional native ground strikes, with one persistent worker that does not block completion. Saved weather is restored at intermission or mission ending; the public snapshot restores local lightning on existing/JIP clients.

[Officer Hunt](OFFICER_HUNT.md) is in the later primary pool from wave 10, with singleton/two-intervening-wave cooldown and reciprocal FOB exclusion. Its registered producer blocks completion through setup and officer resolution/expiry, then finishes after pending child drainage. The default command squad has one officer/four guards and sends four infantry every 90 seconds, capped at two living reinforcement teams/eight soldiers. The ten-minute fallback stops reinforcements and releases the living command squad to assault.

F09 adds encampment to the later primary combat pool as well as the wave 7–9 full pool. The fobAvailable predicate filters candidates by minimum wave 7, Specials Off, current-wave duplication, active/setup singleton and cooldown. BW_FOB_COOLDOWN_WAVES defaults to 2 intervening waves: a successful deployment in wave 7 permits another from wave 10. Failed/cancelled setup does not consume cooldown; Vehicle Never does not exclude this infantry objective. See [F09 implementation and tests](FIXES.md#f09-recurring-fobs).

## Intermission and team state

The [Debug shop](DEBUG_SHOP.md) can force any of the 15 implemented specials. The server queues one choice; the mission loop cancels/drains the current wave and starts the next number with just that modifier plus ordinary infantry, skipping preparation and automatic enemy vehicles. An exact wave/type override bypasses selection restrictions without changing lobby settings; normal behavior resumes on the following wave. Objective safety/capacity and content validation remain in force.

F01 uses a server preparation deadline shared with the final 15-second start warning. A strict majority of living conscious WEST humans can shorten the wait after the configured minimum; phase IDs prevent stale votes affecting a later wave. See [READY_VOTE.md](READY_VOTE.md).

F12 reads existing wave/phase, ticket, bank and public objective state for the team board. Manual pings report positions independently of enemy selection or AI targeting; they add no enemy scanning. See [TACTICAL_STATUS.md](TACTICAL_STATUS.md).

## Budget versus active population

[createWave.sqf](../hostiles/createWave.sqf) calculates ordinary infantry as:

~~~text
teamFactor = max(1, humanPlayerCount × HOSTILE_TEAM_MULTIPLIER)
multiplier = 1 for waves 1–2, otherwise HOSTILE_MULTIPLIER
ordinaryBudget = floor(wave × multiplier × teamFactor)
activeLimit = min(120, 30 + 4 × humanPlayerCount)
ordinaryThreshold = floor(activeLimit × 0.8)
~~~

Both budget and capacity use humanPlayers (excluding headless clients). Fractional player scaling is retained until the final budget is rounded down. Capacity is fixed for the wave, not recalculated on every join/leave.

Example: 25 human players, team multiplier 0.5, multiplier 2, wave 30 gives 750 ordinary infantry total. Active capacity is 120; ordinary infantry can fill only to a total occupancy of 96, leaving room for specials. Specials and crew count toward active occupancy but do not consume the ordinary budget.

[fn_spawnLimited.sqf](../bulwark/functions/fn_spawnLimited.sqf) is the shared server scheduled gateway for active enemy unit/group/vehicle creation. It counts living EAST/RESISTANCE units from allUnits, plus granted reservations. Pending requests retry every five seconds. Group requests reserve their full squad; vehicle requests conservatively count driver and nested turret crew slots. Reservations are allocated in a non-suspending block to prevent concurrent producers exceeding capacity. It is not a strict FIFO queue.

Queue records are [serial, originatingWave, requiredSlots, granted, producerHandle]. The fifth field is server-local and lets administrative cancellation discard orphan records only after their producer has finished. Failed/cancelled requests release their record. Optional guard objects cancel cargo/FOB requests if their carrier/cache is destroyed. Guarded group results are marked as scripted movement until the caller finishes setup and hands them to the controller. The guard's bw_capacityWaiting counter records outstanding guarded work.

Creation helpers can yield, so the gateway rechecks guard/wave validity after creation and deletes cancelled results before releasing reservations. Transport callers also reject cancelled cargo before boarding. Paradrops recheck the 250-metre drop zone after capacity allocation; a hidden inactive pending troop waits for a bounded 120-second return pass when needed, then deploys or is deleted on failure/cancellation.

Never call this scheduled gateway from an unscheduled context. Its empty return is grpNull for groups, objNull for individual units and [objNull, [], grpNull] for vehicles. Callers must handle those outcomes.

An optional sixth argument supplies a finite absolute mission-time deadline; -1 retains the existing indefinite wait. Officer Hunt uses bounded deadlines for setup and reinforcement admission, with creation results discarded if the deadline elapsed while the engine helper ran. A reinforcement deadline cannot outlive the objective's internal mission-time expiry.

## Completion and cancellation

A wave completes only when the ordinary remaining budget is zero, finite producer handles are done, the capacity queue is empty, EAST/RESISTANCE units are gone and no live FOB cache remains. A producer can include transport departure/cleanup, so its completion may lag the last infantry kill.

Finite producers are registered through queueHostiles, with dispatcher children tracked where necessary. Persistent effects that intentionally run until wave end must not be registered as never-ending completion blockers. They instead capture a wave ID and use waveActive to stop during intermission/extraction or a later wave. Artillery projectiles are removed at intermission.

Do not replace wave completion with only “no enemies alive”: a temporarily empty battlefield can still have queued troops. Do not reuse an uncaptured global wave number in a delayed child script.

## Infantry control

Every five seconds, moveHosToPlayer registers unscored Zeus enemies and dispatches the controller to the current group owner. [controlEnemyGroup](../bulwark/functions/fn_controlEnemyGroup.sqf) owns task transitions for eligible infantry:

- Group-level base mode is rush or creep. Creep is selected once for a squad, not independently for members sharing a movement task.
- CQB enters below 10 metres and remains active until the target is at least 25 metres away. A naturally completed CQB task is latched until exit rather than restarted every poll.
- Tagged suicide bombers receive direct pursuit, without a competing LAMBS rush task.
- Old task/watch handles are terminated before transitions. LAMBS soft reset preserves the group reference and clears waypoints.
- A local watchdog stops the task on lease expiry, ownership loss, player takeover, scripted handoff, phase/wave change or group death. The server renews the lease while dispatching.
- Player-containing groups, remote-controlled units and scripted transport/custom-waypoint groups are excluded. Stationary/NonCQB units are not generic infantry targets.

Helicopter cargo is scored/protected immediately; after insertion it joins the same controller. Truck drivers use transport waypoints. FOB defenders patrol until cache destruction. Vehicle/aircraft controllers still have separate task/flight logic; don't assume every vehicle is driven by controlEnemyGroup.

## Defense objects and stuck-unit cleanup

solidobject.sqf maintains one watcher per defense object, pauses while held and only detonates tagged bombers. Ordinary infantry keeps engine/LAMBS pathfinding; the old persistent CARELESS/speed/stance overrides were removed.

clearStuck samples local, on-foot managed rush/creep infantry with an outstanding MOVE/FOLLOW order. It requires two consecutive 60-second samples with little movement toward a stable distant destination, excludes combat/player/scripted groups and requires distance from players. It never destroys a vehicle based on a crew sample. Nonlocal/HC infantry is skipped by this server cleanup.

All of these behaviors still require the engine tests listed in [DEVELOPMENT.md](DEVELOPMENT.md).

## FPV Operator source implementation (2026-10-30)

Station lifecycle, bounded crewless drone director, target fairness/cover checks, optional-addon wave selection, Debug entry and PL/EN HUD/search area are implemented. See [FPV_OPERATOR.md](FPV_OPERATOR.md) and [addon integration](FPV_MOD_INTEGRATION.md). Fixed settlement candidates supplement explicit sites/markers; they are not editor-verified navigation points. Static checks passed; the adapter/lifecycle harnesses and in-game multiplayer/flight/detonation acceptance remain unrun.
