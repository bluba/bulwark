# Officer Hunt implementation plan

Status: implemented in source on 2026-10-29; Arma acceptance pending. This document preserves the original design and acceptance checklist. See [OFFICER_HUNT.md](OFFICER_HUNT.md) for delivered configuration, state and validation limits. Proposed APIs/work packages below describe the design history, not a remaining implementation checklist.

## Player experience and initial scope

An enemy officer establishes a small observation post outside the immediate defense perimeter. Players receive an approximate search area and the message: **Enemy command post detected. Eliminate the officer to stop reinforcements.** The officer and four guards defend the post while small reinforcement teams periodically attack the players.

Killing the officer stops new requests on the next one-second monitor tick, cancels requests still waiting for capacity, removes the search objective and releases surviving guards to attack. Waiting capacity requests retire on their next gateway poll, normally within five seconds. Reinforcements already deployed remain in combat. The normal wave continues until its other enemies and producers are cleared.

The officer uses normal damage and existing faction equipment, with a recognizable officer/leader class where available. No invulnerability, unusually accurate AI, escape vehicle, capture interaction or extra currency system is included. Existing kill scoring remains; there is no additional shared-bank reward in the first version. An officer killed by another enemy, artillery or lightning still stops the command post.

## Proposed defaults

| Rule | First implementation |
| --- | --- |
| Eligibility | Wave 10 onward, through the existing primary combat-special draw; no additional independent roll. |
| Frequency | At most one planned, setting-up or active Officer Hunt. Two intervening waves between successful deployments: wave 10 permits another from wave 13. |
| Specials / vehicles | Specials Off disables selection and direct startup. Vehicle Never does not exclude this infantry event. |
| FOB stacking | Officer Hunt and encampment are mutually exclusive in the same wave, in either draw order. Weather and other combat specials remain compatible. |
| Initial troops | One officer and four guards; five special-capacity slots, outside the ordinary infantry budget. |
| Post distance | `max(300, BULWARK_RADIUS + 100)` to 200 metres farther from a captured `spawnAnchor` position. Normal setting: 300–500 metres. |
| Site attempts | At most 16 outdoor candidates; skip if none passes. |
| Search marker | Fixed 150-metre-radius area containing the post; deliberately offset from its exact location. No live officer tracking or 3D icon. |
| Post behavior | Officer/guards defend or patrol within roughly 50 metres. Keep normal combat reactions and damage. |
| Reinforcements | Four infantry every 90 seconds, with the first request 90 seconds after successful activation. |
| Local reinforcement cap | At most two living reinforcement teams, at most eight living reinforcement soldiers; at most one pending request. |
| Spawn admission deadline | 60 seconds per initial/reinforcement request; a timed-out reinforcement opportunity skips. |
| Objective lifetime | 600 seconds from activation. Expiry ends reinforcements and sends the surviving command squad into the ordinary assault. |
| Extra reward | None beyond existing kill scoring. No reward on failure, deletion, expiry or cancellation. |

Use a small set of validated settings in `editMe.sqf` for enabled, minimum wave, cooldown, guard count, reinforcement size/interval/team cap, request timeout and lifetime. Clamp quantities to the limits above for the first release; reject malformed values rather than accidentally creating unbounded producers. Do not add lobby parameters initially.

## Existing source constraints

| Source behavior | Implementation consequence |
| --- | --- |
| `fn_startWave.sqf` selects a complete `waveTypes` plan, then fixes `defectorWave` before dispatch. | Add `officerHunt` to the later `_nonModified` primary pool. Capture the resulting side/classes once; do not read changing global flags in delayed children. |
| `fn_fobAvailable.sqf` already filters FOB duplication, live/setup state and cooldown. | Add a separate officer predicate. Extend FOB eligibility to reject an Officer Hunt already planned or admitted; the officer predicate rejects planned/live/pending FOBs. Selection and actual setup both enforce exclusivity. |
| `queueHostiles` registers a script before it can run. | Register the objective producer immediately so an empty battlefield cannot complete the wave during placement/admission. Register each finite reinforcement child too. |
| Wave completion checks jobs, requests, infantry budget, hostile units and active FOBs. | The registered officer producer blocks completion until officer death, abort or expiry. No new completion predicate or reuse of `BW_ACTIVE_FOBS` is needed. |
| `spawnLimited` can suspend for capacity, and rechecks wave/guard after engine creation. | Keep the lifecycle monitor separate from asynchronous reinforcement requests. Pass the officer as guard and retain the post-creation check. Add an optional admission deadline to the gateway. |
| The generic infantry controller rejects `bw_scriptedMovement`, `bw_stationary` and `NonCQB`. | Protect the post during defense, then explicitly clear all relevant exclusions during assault handoff. Follow the mortar/FOB fixes rather than clearing only one flag. |
| AI task handles belong to the current group owner. | Run post-defense tasks, resets and assault handoff on that owner. Stop old tasks on ownership loss, phase end and Zeus/player takeover. |
| `clearStuck` deliberately skips stationary/scripted infantry. | The objective needs its own 600-second fallback; ordinary anti-stuck cleanup cannot rescue an inaccessible officer while the post is active. |
| F12 consumes a fixed `BW_TEAM_STATUS` array. | Add a separate officer snapshot and include it in the HUD change key. Preserve existing team-status indices and manual ping behavior. |
| Existing killed scoring runs only when its handler executes on the server. | Preserve the current scoring registration and test headless-client ownership explicitly. Do not attach the objective's authority or termination solely to the current scoring handler. |

## Placement, classes and activation

1. Validate the feature settings and faction class lists, then atomically reserve a singleton record containing a new monotonically increasing instance ID and originating wave. The record itself represents pending setup.
2. Capture one spawn anchor. Examine up to 16 outdoor candidates in the configured annulus. Reject water, map edges, steep/unsupported ground, solid geometry, insufficient troop clearance and sites within 200 metres of living humans or the Bulwark. Do not use an unchecked safe-position fallback. A small decorative post is optional; scenery must not be required for the objective to work.
3. Resolve the officer/guard profile from the active faction configuration. Provide validated leader/officer candidates for the Russian and legacy modes; use a validated leader-class fallback from the applicable hostile catalogue. Defector mode uses RESISTANCE and its existing infantry pool. Skip with a diagnostic if no valid five-unit profile can be formed. Do not add a new mod dependency.
4. Submit the five-unit initial squad through `spawnLimited` as a special group with a 60-second deadline. Capture the unit corresponding to the officer entry explicitly and select it as leader. Never later identify the objective using `leader _group`, because leadership changes after death.
5. After creation, recheck instance ID, wave, deadline, minimum distances and that the officer exists/alive. Remove partial/invalid results; do not activate a post without its officer. Register scoring, ownership tags and cleanup tracking before exposing units to the periodic controller.
6. Mark the post group for scripted defense, set stationary/NonCQB exclusions and dispatch the owner-local defense controller. Publish the search snapshot and initial notification only now. Commit the successful-deployment cooldown at this point; invalid classes, failed placement and cancelled admission do not consume it.

The post stays at its captured site when the truck or players move. It does not teleport to follow them. Geometric placement checks do not prove a walkable route: representative Altis locations need engine testing.

## State, scheduling and capacity

Proposed server state:

- `BW_OFFICER_SERIAL`: monotonically increasing instance counter.
- `BW_OFFICER_LAST_WAVE`: last successfully activated deployment, initially -1.
- `BW_OFFICER_HUNT`: one named-field record or an empty map. Fields include `id`, `wave`, `state`, `officer`, `postGroup`, `position`, `searchCenter`, `side`, `classes`, `activatedAt`, `expiresAt`, `nextRequestAt`, `reinforcementGroups`, `pendingJob`, `worker` and owned scenery.
- `BW_OFFICER_RESULT`: last terminal instance/reason for diagnostics, without a claim/reward API.

States: `settingUp -> active -> resolved/cancelled`. Terminal reasons distinguish officer death, external deletion, timeout, invalid content/placement, extraction and mission ending. State transitions and singleton/cooldown mutations are instance-bound and non-suspending.

The registered producer owns setup and then checks its tracked officer/state once per second. It never blocks inside a reinforcement capacity request. At each opportunity, prune dead/empty tracked teams; if two teams are still alive or a request is pending, skip that opportunity. Otherwise launch one registered four-man child and schedule the next opportunity from the current time. There is no backlog or catch-up burst.

Each child carries `[instanceId, wave, officer, side, classProfile, spawnPosition, deadline]`, uses the officer as `spawnLimited` guard and rechecks instance/active state after creation. Its deadline is the earlier of `time + 60` and the objective's mission-time expiry, so expiry cannot leave a fresh minute of queued work behind. Keep an internal mission-time expiry alongside the public `serverTime` expiry; do not compare timestamps from different clocks. Successful troops receive scoring once, enter `waveUnits`, and hand off to the normal owner-local assault controller. The cap is checked again before admission. A child cannot publish troops after its officer died, its instance closed or its deadline expired.

Add a sixth, optional `_deadline` argument to `spawnLimited`, default -1 for existing indefinite waits. A supplied deadline uses server mission `time`; validate its type/finite value. Check expiry before queuing, in each wait iteration and after engine creation; release the reservation and return the usual empty value on expiry. Keep all existing callers and return types compatible. Initial squad and reinforcement requests use this bounded path; do not introduce disposable guard objects solely to implement a timeout.

On officer death or expiry, mark the record terminal before handoff. Stop launching children. Death cancels guarded waits naturally; expiry also needs its capped request deadline and the child instance check, since the officer may still be alive. Keep the closing producer registered until the outstanding child exits, normally by its next five-second poll, or after discarding any creation already in progress. Never terminate a worker inside `spawnLimited` and abandon its reservation. Clear public objective data promptly, independently of that closing wait.

The producer must finish after child drainage and guard handoff. It must not wait for the entire wave after the officer objective closes, which would reproduce the earlier FOB completion deadlock.

## Defense, resolution and cleanup

Use one small owner-local post controller rather than a competing generic rush task. Retain the same group identity across task resets. Its local task/watch handles must stop when the group becomes nonlocal, its lease expires, the officer objective closes, combat ends or player/Zeus takeover occurs. Renew/reassign through the existing server phase tick; do not assume script handles transfer to a headless client.

| Situation | Required outcome |
| --- | --- |
| Officer dies, including from another hostile or weather | Close once; stop new requests; notify that reinforcements stopped; surviving guards join the assault; deployed reinforcement teams remain. |
| Officer is externally deleted | Cancel the objective without a kill-success claim; stop production; release guards. No replacement officer or repeated deployment in the same wave. |
| 600-second lifetime expires | Announce that the command post is abandoning its position; stop production; release officer and guards to assault. No free kill or completion reward. |
| Extraction, preparation, next wave or mission end | Close pending/active setup; cancel/drain spawn work; remove owned live units/scenery and display state. No surviving stationary officer or hidden completion blocker. |
| Failed setup/admission | Delete partial units/groups/scenery; release the pending singleton; finish the registered producer; leave cooldown unchanged. |
| Repeated or stale cleanup | No effect on a newer instance; no duplicate notification or reward. |

Assault handoff runs on the current owner: stop the defense task/watch, soft-reset while preserving the group, clear `bw_stationary`, set `aiMode` and `bw_baseMode` to rush, clear `bw_scriptedMovement`, then call `controlEnemyGroup`. Remove only event-owned objects during cancellation; do not delete unrelated units subsequently joined by Zeus or players. Use instance tags and takeover checks for ownership-sensitive cleanup. Track event-created units independently of their current groups so group transfers cannot lose cleanup responsibility. Ordinary corpse cleanup can retain resolved combat casualties through `waveUnits`.

Initialize state in `missionLoop.sqf`, add explicit instance-aware cleanup in `fn_endWave.sqf` and before final mission ending, and add defensive prior-instance cleanup before the next wave increments. Add a small server maintenance helper, `fn_updateOfficerHunt.sqf`, called from the existing `tacticalState` phase tick. It renews post-controller ownership/leases and detects an unexpectedly finished producer while its record remains active. It inspects only the tracked record/handles, logs the failure and enters the same closing/drain/handoff path. Recovery cannot depend on the failed worker detecting its own failure or clearing its own completion state.

## Map, HUD and join-in-progress

Publish `BW_OFFICER_STATUS = [id, wave, searchCenter, searchRadius, expiresAt]`, or `[]` when absent. Use `serverTime` for the public expiry. Keep the officer object reference, actual position and next spawn request server-side; the marker is a fixed search area, not a target tracker. Generate its center with at most 75 metres of offset so the post remains inside the 150-metre circle.

Extend the existing tactical client tick to maintain one WEST-local search marker and one HUD line: **Enemy officer active — reinforcements incoming**, with the coarse remaining objective time. Include snapshot/countdown changes in the HUD cache key. Add English/Polish stringtable entries for the marker, HUD, initial warning, success, abandonment and cancellation notices. Current snapshots recover after JIP, respawn or HUD recreation; success messages are transient and not replayed. Locally hide stale markers on wave/phase mismatch or expiry while awaiting server cleanup.

This preserves the mission's existing public-snapshot/display-side policy; it does not establish confidential transport or a complete malicious-client boundary. No new client-callable mutation/reward RPC is required. Any owner-local AI entry point must accept remote commands only from server owner 2 and validate the instance/group.

## Delivery order and proposed files

Names below describe proposed APIs, not functions that already exist.

| Step | Work | Gate before continuing |
| --- | --- | --- |
| 1 | Settings/profile validation in `editMe.sqf`; `bulwark/functions/fn_officerHuntAvailable.sqf`; extend `fn_fobAvailable.sqf`. | Wave 10 minimum, successful-deployment cooldown, singleton and FOB exclusivity in both selection orders; Specials Off and Vehicle Never. |
| 2 | Optional deadline in `fn_spawnLimited.sqf`; extend `tests/spawnCapacity.sqf`. | Waiting and in-creation expiry clean up results/reservations; existing default callers behave as before. |
| 3 | Bounded `fn_findOfficerPost.sqf`; `hostiles/officerHunt.sqf`; `fn_endOfficerHunt.sqf`. | Invalid/partial setup cannot publish a target or strand the wave; activation commits once. |
| 4 | `fn_controlOfficerPost.sqf`; `fn_updateOfficerHunt.sqf` from the existing `tacticalState` server tick. | One task per owner; takeover/transfer cleanup; same-group rush handoff clears every exclusion; failed-producer recovery has an independent owner. |
| 5 | `hostiles/officerReinforcements.sqf`, dispatched through `queueHostiles`. | Officer monitoring remains responsive at capacity; one pending job, two-team/eight-unit cap, no catch-up burst or late squad. |
| 6 | Register new functions in `bulwark/Functions.hpp`; primary selection/dispatch in `fn_startWave.sqf`; lifecycle hooks in `missionLoop.sqf` and `fn_endWave.sqf`. | Correct completion gating through setup, death, expiry, cancellation and child drainage. |
| 7 | `fn_tacticalClient.sqf`, `score/functions/fn_updateHud.sqf`, `stringtable.xml`; add `tests/officerHunt.sqf`. | Fixed search area, stable existing status layout, JIP/respawn/HUD recovery and translated labels. |
| 8 | Update current scenario/wave/architecture guides, fix record and development test index. | Record exact checks, pending engine acceptance and tuned defaults. Do not create a PBO. |

## Required verification

Static checks: SQF/config strings/comments/delimiters; CfgFunctions and script references; all selection/cleanup call sites; XML parsing and English/Polish placeholder parity. These do not compile SQF or emulate locality/pathfinding.

The new idle-session engine harness should cover actual predicates, producer, spawn gateway and cleanup, using controlled fixtures/stubs only where needed. Save/restore settings and functions; remove test actors. Include:

- Specials On/Off, wave 9/10, duplicate/concurrent starts, cooldown commit only after activation, and FOB exclusion in both plan/setup orders.
- Invalid classes, no site, partial squad creation, setup timeout, extraction during admission and no late objective publication.
- Full capacity: officer dies while a child waits; officer disappears during engine creation; admission expires during creation; no survivors at world origin and no leaked queue entries.
- Reinforcement cadence, one pending request, live-team/eight-unit cap, casualty pruning, no backlog after a long stall and no ordinary-budget consumption.
- Officer death/deletion, expiry with a living officer, repeated/stale cleanup and all termination paths; no circular job/wave wait.
- Surviving guards regain assault eligibility, completed producers leave no hidden blocker, event ownership survives group transfers, and unrelated/controlled units are preserved.
- Published snapshot/marker cleanup and recoverable HUD state without changing `BW_TEAM_STATUS` indices.

Dedicated acceptance with two clients and optionally a headless client: both faction modes and defector stacking; thunderstorm/mortar/suicide combinations; actual officer readability and search difficulty; post pathfinding in towns/industrial/coastal areas; mobile Bulwark relocation; kill scoring and task handoff across ownership transfer; Zeus takeover/release; JIP before/after resolution; and extraction during setup/capacity waits.

Measure active hostile counts, pending requests, live reinforcement groups, objective/total-wave duration, server FPS and object/task counts across several late waves. Start with the fixed small troop profile above; do not scale it up until the shared capacity and pacing behavior are observed in play.
