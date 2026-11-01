# Regular vehicle tickets — implementation

Regular vehicle tickets are enabled by default. Configure hostiles/vehicleSettings.sqf; settings are loaded and snapshotted at each wave start. Set BW_VEHICLE_TICKETS=false there to restore the independent rolls.

## Budget and selection

Starting at ARMOUR_START_WAVE, target = min(30, (3 + 0.75*age) * min(2, 1 + 0.30*max(0, humans-2))). Roll an integer from max(2,floor(target*0.8)) through ceil(target*1.2). Never and debug-forced specials suppress regular vehicles. Infantry retains fractional player scaling.

The planner purchases exact class/cargo packages from fn_vehicleCatalogue.sqf. It filters absent/non-public classes and insufficient cargo capacity. Package prices include crew and cargo. Catalogue arrays are [class, cost, reserved zero, role, cargo count]. No dynamic unknown-class fallback; mortars, artillery, unarmed scouts and ambiguous base classes are excluded. RU, curated vanilla Legacy, and NATO defector pools are supplied.

First three vehicle-enabled waves allow two purchases; later waves allow four. At most two identical packages and one combat helicopter. Before age 14, at most one heavy/combatAir purchase; later two. Preference weights favour patrol, motorised, armour or air compositions, normalize by role pool size and reduce recently used class weight. Unused tickets expire.

## Deployment and specials

A registered finite scheduler waits 15–25 seconds initially, and 25 seconds between purchases. It spawns at most one active regular vehicle early, two later; early heavy overlap is restricted. Each pending purchase has a 180-second admission deadline. Failed requests are not retried or refunded in this first implementation, preventing replacement exploits. No change to player respawn tickets.

Special selection, quantities and budgets remain separate. The shared spawn gateway serializes conventional hostile aircraft (excluding UAVs) and known truck deliveries. Earlier same-channel requests go first. Admission checks and manpower reservations are atomic. Aircraft retain the channel while alive and crewed; special trucks release after unloading. The regular delivery adapter removes its carrier after unloading/paradrop. Requests blocked by another operation expire after their deadline; therefore requested special quantities can exceed actual deployments.

Regular cargo uses valid Level 2/defector infantry with a fixed paid headcount, spawned through the manpower gateway. Helicopter transport delivers by parachute. Partial cargo admission is possible if the carrier dies or capacity times out; no refund occurs. Scheduler outcomes and the complete purchased plan are recorded in the server RPT and BW_VEHICLE_PLAN. Combat-unit destruction does not restore tickets.

The scheduler remains in BW_SPAWN_JOBS until pending purchases terminate. Vehicles use the existing AI, scoring and wave-unit registration. Shared arrival checks never reserve manpower while merely waiting for an occupied channel.

## Implementation choices versus the proposal

Arrival coordination is implemented at the existing spawn gateway rather than a second reservation service. This makes creation and channel reservation part of one atomic admission decision. Transport processing is sequential within the regular scheduler, conservatively spacing packages. There is no refund/retry loop. Shared FIFO uses actual producer request order, not unconditional special priority. Budget tuning is configurable; package and timing limits are initial fixed defaults in the planner/scheduler.

The previous report's regular vehicle probabilities and family lists describe compatibility mode. Ticket mode uses the catalogue and rules in this document. Special and ordinary infantry sections remain applicable.

## Validation

Run on a server/editor with mission functions loaded:

~~~sqf
[] execVM "tests\vehicleTickets.sqf";
~~~

This exercises the real planner across waves 1–100, seven player counts and three deterministic random streams (2,100 plans), including spending, global start/Never handling, budget-only eligibility, composition limits, repeatability, Never and empty catalogues. It creates no units. Existing tests/spawnCapacity.sqf checks the manpower gateway; it requires an idle server as documented in that file.

Runtime acceptance still requires Arma: verify convoy/airstrike overlap, cargo unloading/parachutes, blocked-channel timeout, extraction and debug cancellation, missing addons, and score/AI behaviour. No Arma runtime is available in the coding environment; added SQF tests are not claimed as executed here.

## Scheduler bug fixes

Empty purchase plans now return immediately. The 25-second interval only applies between purchases, so there is no final artificial wait. Cargo uses a current carrier position, verifies successful boarding atomically, and discards unseated units. Helicopter disembarkation is staggered; a failed live-aircraft approach no longer drops troops at its timeout location. Outcomes distinguish failed deliveries and cancellation from successful arrival.

Additional engine regression: run tests/vehicleTicketEmptyPlan.sqf during an active wave. It checks that an empty plan returns promptly without spawning. This test requires Arma and has not been executed in the coding environment.

## Budget-only model eligibility

All regular catalogue vehicles are eligible from ARMOUR_START_WAVE if affordable. Never still disables regular vehicles. The former per-model unlock field is reserved zero and ignored by the planner. Composition and active-arrival limits remain; specials keep their independent selection and quantities.

The first purchase is drawn from entries costing at least ceil(75% of the most expensive affordable candidate). Theme and recent-use weights select within that band. Subsequent purchases use the remaining budget for support. This guarantees an upper-band main purchase while allowing several strong alternatives, without overspending.

Cost review: BRDM-2 scout 4; Vodnik AGS and Hunter/Ifrit GMG 6; ZU-23 truck 8; armed light helicopter 10; Mi-8 troop transport 7; Ghost Hawk troop transport 8. Other prices retained. These balance estimates account for protection, explosive weapons, mobility and paid cargo; in-game tuning remains necessary.

Review follow-up: the anti-repeat weight now remembers the first successfully deployed purchase of the preceding wave, rather than its final support vehicle. Each helicopter passenger also rechecks the live carrier distance against the drop zone before exiting; drifting out of range aborts the remaining drop. Ticket prices are unchanged by this review. Static checks passed; transport behaviour still needs an Arma playtest.
