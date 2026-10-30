# Code architecture

Paths in this document are relative to the active mission directory, dynamicBulwarks.Altis. Documentation updated 2026-10-29.

## Startup and execution

~~~text
Arma mission load / description.ext CfgFunctions
  ├─ initServer.sqf
  │    ├─ locationLists.sqf + loot/lists.sqf + hostiles/lists.sqf
  │    ├─ editMe.sqf → required-content checks → bulwark/createBase.sqf
  │    ├─ missionLoop.sqf → startWave → async createWave → endWave
  │    ├─ extract.sqf + hostiles/clearStuck.sqf
  │    └─ periodic AI dispatch, revival and support cleanup
  └─ initPlayerLocal.sqf + onPlayerKilled.sqf + onPlayerRespawn.sqf
       └─ local UI/actions, damage handling and server requests
~~~

[missionLoop.sqf](../missionLoop.sqf) owns mission progression. [fn_startWave.sqf](../bulwark/functions/fn_startWave.sqf) increments the wave, initializes shared spawn state, selects/dispatches specials, and starts an asynchronous hostile producer. The main loop can therefore check defeat/extraction while reinforcement batches are still waiting.

Arma automatically executes the standard init and player lifecycle entry points. Functions are registered through each subsystem's Functions.hpp included by description.ext. A registered function named example is implemented as functions/fn_example.sqf; standalone scripts are launched with execVM. Do not assume every SQF file in the tree is active.

## Directory map

| Location | Responsibility / useful starting points |
| --- | --- |
| bulwark/ | Base creation, shop UI, bonus location, item conversion and defense watcher. |
| bulwark/functions/ | Mission phases, player predicates, capacity gateway, AI controller, respawn and purchase helpers. |
| hostiles/ | Wave budget, enemy class lists, spawners, specials, transports and anti-stuck cleanup. |
| score/ | Kill points, HUD, shared bank and server purchase processing. |
| supports/ | Player support catalogue/actions, strikes, aircraft supply and troop delivery. |
| build/ | Pickup, drop and placement of purchased objects. |
| loot/ | Loot lists, placement, cleanup and spinning box. |
| area/ | Area/location helpers; check call sites before assuming enforcement is active. |
| dialog/ | UI resource definitions. |
| sound/ | Sound functions/resources. |
| nssfnc/ | Imported helper functions used by transport/AI scripts. |
| tests/ | Manually invoked Arma regression scripts. Not launched by mission startup. |
| docs/ | Current guides and historical review records. |
| stringtable.xml | English fallback and Polish translations for the tactical board and ping labels. |
| install/ | Inherited installation material; current source and documentation take precedence. |

## Ownership and multiplayer boundaries

The server owns mission state, spawn reservations, enemy budgets, cash/ticket decisions and object creation. Clients own player UI and player-local damage/revival operations. A purchase sends a catalogue ID; the client is not trusted to choose its price or create the reward.

Movement orders must run where the AI group is local. The server periodically dispatches controlEnemyGroup to groupOwner when needed. That function rejects remote requests not originating from server owner 2, checks group locality and excludes player/Zeus/scripted groups. Script handles are local to the machine running the task; do not broadcast them as a substitute for ownership coordination.

Published values include attkWave and buildPhase. Many other globals are server-only. In particular, code running on a headless client must not assume every server missionNamespace variable is available. The AI controller uses published phase/wave information and a renewed local lease.

## Main state

| State | Meaning / owner |
| --- | --- |
| attkWave | Current wave, server-set and published. |
| buildPhase | Intermission flag, server-set and published. |
| runMissionLoop / missionExtract / missionFailure | Server progression and ending state. |
| waveUnits | Three generations of tracked objects/units for cleanup; not the authoritative capacity count. |
| BW_ENEMY_LIMIT | Active capacity snapshot established at wave start. |
| BW_INFANTRY_REMAINING | Ordinary infantry budget remaining; finite producer jobs also gate completion. |
| BW_SPAWN_QUEUE | Capacity requests/reservations; record shape described in WAVES_AND_AI.md. |
| BW_SPAWN_JOBS | Handles for finite producers that must finish before wave completion. |
| BW_ACTIVE_FOBS | Cache objects whose survival prevents wave completion. |
| BW_FOB_LAST_WAVE / BW_FOB_SETUP_PENDING | Server-only successful deployment cooldown and singleton setup reservation. |
| BW_READY_PHASE / BW_READY_OPEN / BW_READY_VOTERS | Server-owned preparation vote generation, acceptance flag and voting UIDs. |
| BW_PREP_DEADLINE / BW_READY_MIN_DEADLINE | Server-only shared wave-start deadline and earliest vote-driven shortening time. |
| BW_READY_STATE | Published [phase, open, voter UIDs, eligible count, required majority] snapshot. |
| BW_TEAM_STATUS | Published [wave, phase label, tickets, bank, active FOB count, bonus active] snapshot. |
| BW_TACTICAL_PINGS | Published records [UID, author object, kind, position, author name, expiry serverTime]. |
| BW_PING_TIMES | Server-only UID cooldown map; retained across player respawn/reconnect. |
| BW_WAVE_PROJECTILES | Artillery rounds tracked for intermission removal. |
| BW_STORM_STATE | Published [wave, active, lightning level] snapshot used by the existing client tick/JIP. |
| BW_OFFICER_HUNT / BW_OFFICER_LAST_WAVE | Server-owned setup/active/closing command-post record and successful-deployment cooldown; separate finite reinforcement child. |
| BW_OFFICER_STATUS | Published [id, wave, search center, radius, serverTime expiry]; approximate search area/HUD, without officer object reference. |
| BW_STORM_JOB / BW_STORM_SAVED / BW_STORM_TARGETS | Server-only persistent worker, saved weather and disposable strike targets; explicit phase/mission cleanup, outside completion jobs. |
| bw_respawnReserved | Per-corpse reservation protecting a paid respawn. |
| bw_scriptedMovement | Group flag protecting transport/custom-waypoint phases from the generic AI controller. |
| bw_baseMode / bw_aiMode | Preferred infantry task and current local task mode. |

## Preparation votes and tactical UI

The mission loop remains the only wave-start owner. endWave opens a new ready-vote phase and shares its deadline with startWave's final warning. requestReady validates caller ownership and the captured phase; updateReadyVote recomputes eligibility and commits shortening without suspension. See [READY_VOTE.md](READY_VOTE.md).

Existing server phase ticks call tacticalState; combat/objective transitions also refresh the public board snapshot. The existing readyAction client loop calls tacticalClient once per second for ping actions, local marker expiry and HUD recovery. requestPing validates manual positions, author ownership and UID cooldown; it never tracks or discovers enemy objects. The score HUD reuses its display and reads the public snapshot. Client-side localization comes from stringtable.xml. Published ping data is not a confidential side-only channel, although only WEST clients render the markers. See [TACTICAL_STATUS.md](TACTICAL_STATUS.md).

## Finding an implementation safely

Search references to a script/function before editing it. The active defense watcher is bulwark/solidobject.sqf, not the commented-out hostiles/solidObjects.sqf. ParaDropNew.sqf is active; ParaDrop.sqf is legacy. checkBulwark.sqf, tempCodeScript.sqf and other experiments must not be enabled just because they exist.

Class identifiers, variable spellings and some filenames contain historical typos. Avoid broad renaming without checking configuration, string-based calls and remote-execution entry points.
