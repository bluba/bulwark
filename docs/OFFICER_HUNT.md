# Officer Hunt

Implemented in source on 2026-10-29; Arma acceptance remains pending. The [implementation plan](OFFICER_HUNT_IMPLEMENTATION_PLAN.md) records the design; this document describes delivered behavior.

## Gameplay

From wave 10, Officer Hunt can be selected as the primary combat special. A command post contains an officer and four guards by default, roughly 300–500 metres from a captured player spawn anchor at the normal mission-area setting. A red 150-metre search area contains the post without revealing the exact officer location. The team HUD shows that reinforcements are incoming and the remaining objective time.

The post defends/patrols locally. Every 90 seconds it may send four infantry to attack, with at most two living tracked reinforcement teams and eight living reinforcement soldiers. Only one request can be pending. All troops count against the mission's shared hostile capacity; they do not consume the ordinary infantry budget. Requests that cannot fit expire after 60 seconds; missed opportunities do not accumulate.

Officer death stops further requests within the one-second monitor cadence. Pending guarded requests cancel on their next gateway poll, normally within five seconds. Previously deployed reinforcements continue attacking and surviving guards join the assault. Officer deletion cancels the objective without claiming a kill. After 600 seconds, the officer and guards abandon the post and attack; new reinforcements stop. This does not kill the officer or automatically finish the wave. Existing kill scoring applies, without a separate bank reward.

At most one post may be setting up, active or draining pending work. Two intervening waves separate successful deployments: wave 10 permits another from wave 13. Failed placement/admission does not consume cooldown. Officer Hunt and enemy FOBs are mutually exclusive in either selection/setup order. Combat effects from other selection slots and weather, including thunderstorm, can stack. If defector mode is already established by a forced/debug combination, the post uses its faction/profile; defector and officer are normally alternative primary draws. Specials Off disables the event; Vehicle Never does not.

## Configuration

Settings live in `editMe.sqf`. Invalid numeric configuration disables eligibility/startup rather than bypassing caps.

| Setting | Default | Accepted range |
| --- | --- | --- |
| `BW_OFFICER_ENABLED` | true | Only true enables startup. |
| `BW_OFFICER_MIN_WAVE` | 10 | Integer 10–9999. |
| `BW_OFFICER_COOLDOWN_WAVES` | 2 | Integer 0–20 intervening waves. |
| `BW_OFFICER_GUARDS` | 4 | Integer 0–4, plus one officer. |
| `BW_OFFICER_TEAM_SIZE` | 4 | Integer 1–4. |
| `BW_OFFICER_TEAM_CAP` | 2 | Integer 1–2 living tracked teams; hard eight-soldier ceiling. |
| `BW_OFFICER_INTERVAL` | 90 | Integer 30–300 seconds. |
| `BW_OFFICER_TIMEOUT` | 60 | Integer 5–60 seconds. |
| `BW_OFFICER_LIFETIME` | 600 | Integer 60–600 seconds from activation. |
| `BW_OFFICER_CLASSES` | Legacy O_officer_F; Russian rhs_msv_officer | Ordered valid Man-class candidates; first valid class wins. Set after the faction block to override that block. |
| `BW_OFFICER_DEFECTOR_CLASSES` | B_officer_F | Same validation; assigned to RESISTANCE. |

Guards/reinforcements use the selected mode's existing level 2+3 infantry, or DEFECTOR_INF for defectors. If the officer profile has no valid class, the first validated infantry class takes the officer role. Empty/invalid infantry profiles skip the deployment. No additional content dependency is introduced. Native/mod loadout readability still needs acceptance.

## Lifecycle and integration

`startOfficerHunt` validates the profile and atomically reserves a named-field `BW_OFFICER_HUNT` record before registering `hostiles/officerHunt.sqf` through `queueHostiles`. Setup considers at most 16 outdoor positions, with map/land/slope/geometry/clearance checks, 200-metre separation from living humans and the Bulwark, and no unchecked safe-position fallback. Initial squad admission has a deadline. Publication/cooldown require a complete living squad and a second wave/site/instance validation.

The objective producer stays registered during setup, officer monitoring and child drainage. This deliberately blocks wave completion while the officer objective is active. The monitor itself never waits inside a reinforcement capacity request: `hostiles/officerReinforcements.sqf` is a separately registered finite child guarded by the officer. Its deadline is the earlier of the admission timeout and objective expiry; post-creation checks reject dead officers, closed/stale instances, expired requests or breached caps. The ordinary infantry budget is unchanged.

`spawnLimited` now has an optional sixth argument, an absolute server mission-time deadline. Existing callers retain -1 (indefinite capacity waiting). Invalid/elapsed deadlines return the existing kind-specific empty value; elapsed waiting/creation releases reservations and discards the result.

State transitions are settingUp → active → closing. Closing clears public availability and stops new requests before handoff. It lets a pending gateway request unwind naturally rather than terminating it and leaking its reservation. The record is released only after its producer and child have finished. An independent `updateOfficerHunt` call from the existing `tacticalState` server tick renews owner-local post control, detects unexpected producer completion and initiates the same closing path. A failed producer's outstanding child remains bounded by its admission deadline.

Post-defense task handles/watchdogs stay on the current group owner. Lease expiry, ownership loss, phase/wave change, player/Zeus takeover or mixed unrelated groups stop the old task. Assault handoff clears both stationary/NonCQB exclusions and the scripted movement flag, preserving group identity. Unit identity tags and the original tracked unit list survive group transfers. Cancellation deletion is dispatched to each unit owner, which checks local player/remote-control state before deleting only matching event units. Takeover-protected units are preserved. Established reinforcements released by normal resolution are ordinary surviving enemies afterward.

Intermission, next-wave and mission-ending hooks explicitly close a still-owned event. Partial setup results are removed. Current-wave officer completion does not wait for the whole wave, avoiding the earlier FOB producer deadlock. Shared cap/queue mechanics still apply; external Zeus spawns are not prevented by this event.

## Display and multiplayer

`BW_OFFICER_STATUS = [instanceId, wave, searchCenter, searchRadius, expiresAt]` is the published display snapshot, or [] when absent. Expiry uses serverTime; internal capacity/lifetime deadlines use mission time. Clients receive no officer object reference in this snapshot and do not track its exact movements. The existing tactical tick creates a WEST-local search ellipse, updates the HUD cache/countdown and removes stale phase/wave/expired display state. JIP and HUD recreation recover current state; notices are transient. The six-field `BW_TEAM_STATUS` shape is unchanged.

Marker/HUD/start/kill/abandonment strings have English and Polish entries. Server/owner entry points validate execution locality and remote sender owner 2 where applicable. Existing broad remote/public transport remains a separate malicious-client hardening concern. The existing server-only kill-scoring handler still needs headless-client scoring acceptance; the officer lifecycle does not rely on that handler.

## Verification

`tests/officerHunt.sqf` requires an idle disposable server/editor, a usable nearby site, living human anchor, LAMBS and no existing hostile units/objectives. It temporarily replaces the site selector and settings, then uses real producers/gateway: wave/settings/FOB gates, singleton activation, stale cleanup, two-team cap, unchanged infantry budget, officer death while capacity is full, child/reservation drainage, guard handoff, cooldown and expiry with a living officer. Run with Specials enabled and disabled. Fixtures and globals are restored. `tests/spawnCapacity.sqf` additionally checks deadline rejection before queueing, expiry while waiting and expiry during real group creation. Neither harness has been run here.

Static checks cover strings/comments/delimiters, function registrations/script references and XML/translation placeholder consistency. They do not compile SQF or simulate AI/locality. Required acceptance remains: two-client hosted/dedicated sessions, JIP/respawn/HUD, both factions/defectors, Zeus and headless-client transfer/takeover, actual post navigation/officer identification, invalid/partial/failed setup, extraction during spawning, storm/mortar/suicide combinations and late-wave FPS/queue/task counts. No PBO was built.

Verification performed: lexical checks passed for 23 changed SQF/config files; all 52 registered Bulwark function files, 17 active script references and 101 Bulwark call references resolve. Targeted primary-pool/FOB exclusivity, deadline stages, terminal-before-handoff, recovery, eight-soldier cap, ordinary-budget preservation and three cleanup-hook checks passed. XML parsing and placeholder parity passed for all 25 English/Polish keys; 76 local links passed in eight guides. These are source checks only, not execution of either harness.
