# FPV Drone Operator

Implemented in mission source on 2026-10-30; Arma gameplay and multiplayer acceptance remain pending. Requires the optional Ukraine FPV Drone addon (Workshop 3475006113) on server and clients. Missing classes/functions exclude the modifier without creating a dependency in mission.sqm.

## Gameplay and configuration

The late primary-special pool can select FPV from wave 10, subject to the vehicle-wave start gate, enabled specials, two intervening waves and no active/planned FOB or Officer Hunt. Debug offers FPV as the sixteenth special; forcing bypasses selection/cooldown gates, but still requires the addon, capacity and a valid site.

A station consists of an empty ammunition box, operator and two guards (configurable to three). Killing/deleting the operator or destroying/deleting the box stops launches and removes active drones without an explosion. Remaining soldiers join the assault. The same lifecycle handles expiry, exhausted launches, relocation, extraction, debug transitions and wave endings. Station objects cannot be moved or sold through the construction shop.

Defaults in `editMe.sqf`:

| Setting (BW_FPV_ prefix) | Default |
| --- | --- |
| ENABLED / MIN_WAVE / COOLDOWN | true / 10 / 2 intervening waves |
| GUARDS / CAP | 2 / 2 UAVs; solo capped at 1 |
| START_LIMIT / LIFETIME | 10 launches / 480 seconds |
| FIRST_DELAY / INTERVAL_MIN / INTERVAL_MAX | 30 / 35 / 50 seconds |
| DRONE_LIFETIME / TARGET_COOLDOWN | 90 / 20 seconds |
| SETUP_TIMEOUT | 30 seconds for infantry allocation |

Invalid numeric settings reject the modifier. Missed launches are not accumulated. Infantry uses the existing shared capacity queue; crewless drones use a separate hard object cap.

## Station locations

Set `BW_FPV_SITES = [[x,y,0], ...]` for explicit ATL sites; an empty array disables placement. Alternatively create markers named `fpv_station_...`; these take precedence over the fallback. Without either, Altis uses a cached fixed layout of offsets around map-authored settlements. These fallback points have **not** been individually walked or verified in the editor.

At most 96 nearby candidates are checked. A site must be 300–700 m from the Bulwark, on land, nearly level, off roads, clear of nearby obstacles, hidden from living defenders and at least 200 m from them. Vertical and short walk-out rays reject enclosed sites. Geometry checks cannot prove navigation connectivity; curated markers are preferred. If no site passes, the wave continues without a station.

## Flight and counterplay

A single server director updates at 0.1 seconds. Spawn climbs, Search evaluates targets every two seconds, Approach flies at 12 m/s and Attack at 22 m/s. Acquisition considers distance, visibility and recent attack history, then chooses among the best three candidates. A player already assigned another drone is excluded. This version targets living, conscious WEST humans **on foot**; vehicle occupants are excluded.

Terrain and geometry rays gate acquisition, retained tracking, motion and detonation. Losing sight returns to Search; prolonged obstruction, lifetime expiry removes the drone. This is a bounded state machine, not indoor pathfinding. Incoming warnings allow a reaction before attack. Direct bullet hits neutralize a drone without a secondary explosion; the addon's inherited damage filter ignores splash, fire and collision damage.

Only a visible target within two metres can trigger the addon's native payload. There is no extra scripted explosion. Native blast damage can still affect nearby objects and players. Operator/box destruction and wave cancellation take precedence over attack. Locality loss or a connected UAV controller retires the drone.

## UI and ownership

WEST clients receive a localized PL/EN HUD countdown, a 150 m search circle (centre offset up to 75 m), and activation/end/incoming notifications. Public status supports joining in progress and respawn; the existing client loop owns local markers. Station AI control follows group ownership. Server-owned generation, instance IDs, bounded setup and idempotent cleanup prevent stale work from closing a later instance.

## Validation

Static delimiter/string/comment checks, function registrations, script references, XML and PL/EN placeholder consistency have been checked. They are not an SQF compilation or engine test.

In a disposable initialized idle server/editor session, with the addon and prerequisites in each script header:

```sqf
[] execVM "tests\fpvAdapter.sqf";
// Run separately after the probe finishes:
[] execVM "tests\fpvOperator.sqf";
```

The lifecycle harness checks actual setup, singleton/caps, protected crewless spawning, target allocation/cooldown, stale IDs, operator/device removal, expiry, relocation, exhaustion and extraction. It temporarily stubs visibility only for allocation-policy assertions. It does not intentionally test explosions. Both harnesses are **unrun**.

Required engine acceptance: crewless flight stability and sound; exactly one native detonation; direct-bullet interception; cover and terrain; cancellation during capacity waits; addon absent; all players in vehicles; two-client fairness; JIP/respawn marker cleanup; owner migration; debug forcing and normal wave endings. Audit RPT for errors and surviving objects. The addon may change its internal protection flags in future updates; repeat the adapter probe after updating it.

Verbose server RPT diagnostics default to enabled (`BW_FPV_LOG = true`). Search for `[BW FPV]` for setup, activation, launch attempts (ID, success, active count, launches, station state), target selection, state transitions, five-second position/velocity heartbeats, detonation results and termination reasons. Set the option to false to disable. Runtime log acceptance remains pending.

Placement diagnostics now emit `siteRejected` with the rejected position and stage, or `siteAccepted`. The Altis settlement fallback uses fixed 15-degree bearings at 150/350/550/750 m offsets to reduce sparse-catalogue failures. Existing range, visibility and geometry constraints remain in force. Runtime placement acceptance is pending.

Fixed candidate shuffling: BIS_fnc_arrayShuffle receives the position list directly, rather than a nested singleton list. An empty nearby list now exits before geometry checks. Earlier noSite reports and geometry type errors could result from this incorrect argument shape. Engine retest is required.

Search-flight correction: unassigned drones now travel at 14 m/s toward the captured defence area, stopping horizontal travel within 80 m, with a 25 m terrain-relative altitude controller. Search has no separate timeout and remains bounded by the original total drone lifetime. Existing swept collision checks apply. Acquisition still requires current player visibility; unseen player positions do not steer Search. `targetRejected` records per-player exclusion reasons. Flight changes require engine acceptance.

Search wandering: within 150 m of the defence origin, drones switch to 9 m/s random waypoints 25–70 m around a sampled conscious WEST player on foot within 250 m of the origin (fallback: origin). Waypoints refresh on arrival, every 6–10 seconds, or after an obstruction. Altitude varies from 18–28 m above local terrain. Player positions bias the search area even without visibility; actual acquisition/attack still requires line of sight. The total lifetime limit and collision checks remain. `searchWaypoint` logs expose the chosen points. Engine flight acceptance is pending.

Removed the separate Search timeout. A drone continues searching until acquisition or its total configured lifetime expires, subject to existing destruction, collision and station/wave cancellation cleanup.
