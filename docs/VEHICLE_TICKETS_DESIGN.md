# Vehicle tickets: final design and implementation plan

> Superseded model-unlock policy: regular vehicle models now use affordability alone after the global vehicle start wave. First purchase selects the upper affordable cost band. See VEHICLE_TICKETS.md for current prices and behaviour.

Date: 1 November 2026
Status: design baseline. Initial implementation is documented in [VEHICLE_TICKETS.md](VEHICLE_TICKETS.md), including implementation choices and outstanding engine playtests. Numerical defaults below are initial tuning values requiring playtests.

## 1. Scope and decisions

Replace the five independent regular vehicle rolls with a shared, randomly sized per-wave ticket budget. Keep specials independently selected and independently sized. Coordinate arrivals across both systems to reduce simultaneous spikes.

The five regular families are cars, transport trucks, transport helicopters, combat helicopters and armour. Tickets cover their crew and any defined cargo. Ordinary infantry keeps its current fractional player scaling.

Specials do not spend, reserve or reduce regular vehicle tickets. A convoy, paradrop, airstrike, mortar, FOB or FPV event remains a distinct source of wave pressure. Therefore the regular vehicle ticket total is not a measure of total wave difficulty.

Ticket budgets are internal enemy threat points, unrelated to player respawn tickets or shop currency. No player inventory or currency changes are involved.

## 2. Budget calculation

Use the configured ARMOUR_START_WAVE as S. Snapshot human player count H when the combat wave starts, using the existing humanPlayers helper. Mid-wave joins/leaves do not replan purchases.

```text
If vehicles are Never, wave < S, or wave is debug-forced:
    regular vehicle budget = 0
Otherwise:
    age = wave - S
    base = 3 + 0.75 * age
    playerScale = min(2, 1 + 0.30 * max(0, H - 2))
    target = min(30, base * playerScale)
    lower = max(2, floor(target * 0.80))
    upper = max(lower, ceil(target * 1.20))
    tickets = uniform integer from lower through upper
```

Round only the final bounds. The target ceiling is 30 and the maximum rolled budget is 36. Expose growth, spread, player scaling and ceiling in mission configuration for tuning.

For one or two humans with S=5:

| Wave | Target | Tickets |
| --- | ---: | ---: |
| 5 | 3.00 | 2–4 |
| 6 | 3.75 | 3–5 |
| 7 | 4.50 | 3–6 |
| 8 | 5.25 | 4–7 |
| 10 | 6.75 | 5–9 |
| 12 | 8.25 | 6–10 |
| 15 | 10.50 | 8–13 |
| 20 | 14.25 | 11–18 |
| 30 | 21.75 | 17–27 |

An occasional lower budget than the preceding wave is intentional. Tickets expire after the wave; no savings, carry-over or extra budget rolls. If no eligible affordable class exists, skip regular vehicles and log why rather than force an inappropriate fallback.

## 3. Vehicle catalogue

Use explicit entries for each purchasable package. Do not infer threat solely from the old cars/armour/heli arrays.

Required fields:

| Field | Meaning |
| --- | --- |
| id | Stable package identifier |
| class | Exact vehicle class |
| factionMode | RU, Legacy or defector catalogue |
| cost | Positive integer ticket cost, including crew and cargo |
| unlockOffset | Earliest wave relative to S |
| role | Patrol, transport, armour, combatAir or support |
| weight | Positive random-selection weight |
| maxPerWave | Per-package repetition limit |
| adapter | Ground assault, helicopter assault, truck delivery or helicopter delivery |
| cargo | Explicit class pool and troop count, if applicable |
| pressureTags | heavy, combatAir, deliveryAir or deliveryGround |

Two versions of the same truck with different troop counts are different packages. Prices are independent of shop prices and kill rewards.

Validate classes and packages before planning. Exclude absent classes, unsuitable base classes, invalid adapters, nonpositive prices and invalid cargo definitions. A class-existence check is necessary but does not replace an explicit spawnability audit. Catalogue fallback requires a reviewed entry with its own price; never assign an unknown vehicle a generic cheap price.

Use the same cost scale across RU and defector forces. Legacy requires a curated catalogue; do not reuse its first-match dynamic car/armour scan as a ticket catalogue.

## 4. Initial prices and unlocks

| Package type | Tickets | Unlock offset |
| --- | ---: | ---: |
| Light MG vehicle | 2 | 0 |
| HMG vehicle / light scout | 3 | 0 or 2, by class |
| Truck with five infantry | 3 | 2 |
| Truck with ten infantry | 5 | 4 |
| Grenade-launcher vehicle | 5 | 4 |
| AT missile carrier | 5–6 | 4 |
| ZU-23 truck | 6 | 6 |
| Armed APC | 6–7 | 4 |
| Transport helicopter with defined small squad | 6 | 4 |
| Autocannon IFV | 8 | 6 |
| Light armed helicopter | 7–8 | 6 |
| Older tank | 10 | 8 |
| Modern tank | 13–15 | 11 |
| Dedicated attack helicopter | 12–15 | 11 |

Ranges indicate class-specific prices to resolve during the catalogue audit; runtime entries have one fixed cost. Unlock does not guarantee affordability or selection.

Keep stationary mortars, D-30 and other indirect-fire artillery out of the initial regular catalogue. They need emplacement/fire-control behaviour and already overlap separate specials. Unarmed vehicles are eligible only as defined transport packages. This removes misleading light-car eligibility for the existing mortar, PTS, AA truck and AT-carrier entries.

Audit actual addon variants and loadouts before assigning final prices. An MG Vodnik and an autocannon Vodnik must not share a price automatically.

## 5. Planning algorithm

Run a server-only planner once, before spawning. Inputs: wave, player snapshot, faction/defector state, validated catalogue, settings, recent regular plans and injectable random draws.

1. Roll the budget.
2. Filter by faction, unlock and installed classes.
3. Choose a feasible preference: patrol, motorised, armoured or air assault.
4. Draw one suitable main package from affordable entries using preference weights. Early plans can use a light vehicle as their main package.
5. Draw affordable support packages until the package cap is reached or no legal choice remains.
6. Store the complete immutable purchase list and its deployment order.

Every draw recomputes affordability, duplicates and role limits. Use positive weights, not uniform selection across arbitrary numbers of near-identical classes. A preference only affects weighting; it cannot bypass rules. If its candidates disappear, fall back to the general eligible pool.

Multiply the previous wave's main-package weight by 0.5 to reduce immediate repetition without banning it. Preserve replayability by logging the selected preference, budget and purchases; tests supply fixed random values.

Initial composition limits:

- Age 0–2: at most two regular packages.
- Age 3+: at most four regular packages.
- At most two identical packages per wave.
- At most one dedicated attack helicopter per wave.
- Age below 14: at most one package tagged heavy or combatAir in the regular plan.
- Age 14+: at most two such packages, still subject to deployment limits.

No requirement to spend every ticket. Leftovers expire. Planner output includes rolled, reserved and unused totals plus reasons for rejected choices.

## 6. Separate specials: explicit integration policy

Keep existing special selection chances, eligibility, cooldowns and quantities in the initial ticket release. Do not silently remove duplicate specials or cap convoy quantities as part of this change. Those are separate balance changes that should be evaluated after ticket-mode testing.

Special Waves Off continues to affect specials only. Vehicles Never continues to disable regular vehicles and the vehicle specials currently gated by that setting. Debug-forced special waves keep the existing suppression of regular vehicles.

Shared coordination applies to mobile arrivals:

| Producer | Coordination |
| --- | --- |
| Regular ground combat vehicle | Acquires a combat arrival slot |
| Regular combat helicopter | Acquires a combat slot and air-conflict reservation |
| Regular/special truck delivery | Acquires a ground-delivery slot |
| Regular transport helicopter / special paradrop | Acquires an air-delivery slot |
| Special airstrike | Acquires an air-conflict reservation |
| Stationary mortar, artillery, Grad, weather | No mobile arrival slot |
| FOB / Officer Hunt infantry reinforcements | Existing manpower capacity only |
| FPV drones | Existing FPV lifecycle/caps; excluded from initial conventional-air reservation |

Shared coordination does not make all combinations safe: artillery, FPV and infantry objectives remain independent. Logs must distinguish that residual pressure from regular vehicle spending.

## 7. Arrival scheduling

Use one server coordinator and atomic reservations. Every participating producer requests permission before creating the vehicle, then releases the reservation on success completion, failure or cancellation.

Suggested defaults:

- First three vehicle-enabled waves: one active regular combat vehicle.
- Later: at most two active regular combat vehicles.
- At most one heavy/combatAir regular package active until age 14.
- Minimum 25 seconds between regular package departures; random initial delay 15–25 seconds.
- One ground delivery vehicle in its arrival/unloading phase at a time across regular trucks and special convoys.
- One air operation at a time across combat helicopters, transport helicopters, paradrops and airstrikes.

A wave's already-selected special delivery/air request gets first opportunity at the relevant slot. Later requests use request order; priority must not permit unlimited overtaking. Each request has a deadline so persistent pressure cannot stall the wave forever.

Combat slots remain occupied while a deployed vehicle is alive and combat-capable. Delivery slots remain occupied through approach and unloading, then release when the scripted delivery completes or the carrier is removed. Disembarked troops remain subject to existing enemy capacity. Disabled vehicles require a documented combat-capability check; do not free a slot merely because a vehicle briefly stops moving.

Do not hold enemy manpower reservations while waiting for an arrival slot. After acquiring an arrival reservation, call spawnLimited with a deadline. Release the arrival reservation if manpower admission times out. This avoids cross-system reservation deadlocks.

## 8. Lifecycle and accounting

Use unique wave and purchase IDs. State transitions:

```text
planned -> waiting -> spawning -> deployed -> completed
                    -> failed
planned/waiting/spawning -> cancelled
```

Reserve the purchase cost in the plan; never spend more than the original rolled budget. If nothing appeared, allow one placement retry or one same-or-cheaper compatible replacement within the original deadline and reserved cost. No new budget roll and no unlimited refund/rebuy loop.

Once any vehicle, crew or cargo has appeared, the purchase is spent. Player destruction is never a spawn failure. Partial package failure does not grant a whole replacement. Clean up orphaned partially created objects according to existing spawn conventions and log what deployed.

Initial pending-deployment deadline: 180 seconds from the entry becoming eligible for deployment. Admission/placement attempts must use the remaining time rather than resetting the clock. Expired pending entries are cancelled and their unspent reserve expires. This deadline does not despawn a successfully deployed enemy.

On extraction, defeat, debug wave transition or shutdown, cancel pending requests and release all arrival reservations. Prevent old-wave workers from altering current-wave state.

The scheduler remains registered as a finite producer until all planned entries are deployed, failed or cancelled. Delivery child producers remain registered for their own finite work. Do not let a coordinator monitor itself keep the wave alive indefinitely after all work has drained.

## 9. Fit with the current mission

Existing mechanisms to preserve:

- queueHostiles registers producers in BW_SPAWN_JOBS before they run.
- spawnLimited enforces manpower capacity and provides deadline support.
- waveActive rejects work outside the active wave.
- missionLoop requires zero remaining ordinary infantry, no pending jobs/queue, no east/resistance units and no active FOB before completion.

The ticket scheduler must use these mechanisms. Vehicle waiting must not block ordinary infantry creation: createWave should register the vehicle plan/scheduler and continue ordinary infantry spawning independently.

Replace global carCount/heliCount/ArmourCount-driven batch calls with explicit per-purchase parameters. Existing vehicle scripts currently select their own random class; ticket-mode adapters must spawn the class purchased by the planner, with no second class draw.

Resolve defector state before catalogue selection, matching the current startWave ordering. Keep existing scoring, AI behaviour, wave-unit registration and Zeus integration in the adapters.

## 10. Proposed file changes

| Area | Planned work |
| --- | --- |
| editMe.sqf | Ticket settings, feature flag, limits and tuning constants |
| hostiles/vehicleCatalogue.sqf (new) | Explicit regular package definitions for supported faction modes |
| bulwark/functions/fn_vehiclePlan.sqf (new) | Pure budget and purchase planning |
| bulwark/functions/fn_vehicleSchedule.sqf (new) | Registered finite scheduler, deadlines, accounting |
| bulwark/functions/fn_vehicleArrival*.sqf (new) | Atomic request/admission/release helpers and cleanup |
| bulwark/Functions.hpp | Register new functions |
| hostiles/createWave.sqf | Replace regular rolls when ticket mode enabled; preserve ordinary infantry calculation |
| hostiles/spawnCar.sqf, spawnVehicle.sqf, spawnHeli.sqf | Explicit single-vehicle spawning with structured result |
| hostiles/spawnUaz.sqf, KillTeam.sqf | Explicit cargo packages, delivery completion and shared arrival hooks |
| hostiles/ParaDropNew.sqf, airStrike.sqf | Shared air coordination without ticket charging |
| bulwark/functions/fn_startWave.sqf | Initialise per-wave planner/coordinator state and preserve special dispatch |
| missionLoop.sqf, fn_endWave.sqf and debug transition paths | Cancellation, cleanup and completion integration where needed |
| tests/vehicleTickets.sqf (new) | Planner and lifecycle regression tests |
| docs/WAVE_SYSTEM_REPORT.md and Polish counterpart | Document final enabled behaviour and settings |

Names are proposed; reuse existing helpers where inspection reveals an appropriate abstraction. Avoid duplicate spawning logic between compatibility and ticket paths.

## 11. Implementation sequence

### Phase 1 — catalogue and settings

Audit every existing RU/Legacy/defector candidate, actual addon availability and transport loadout. Assign one price, unlock and adapter per included package. Record excluded classes and reasons. Resolve all price ranges before implementation is considered complete.

Deliverable: validated catalogue and configuration, with ticket mode initially disabled for comparison.

### Phase 2 — planner

Implement the deterministic-input planner, budget formula, weighted composition, limits and logs. Run broad offline/engine-compatible plan checks for waves 1–100, supported player counts, all faction modes and missing-addon subsets.

Deliverable: reproducible plans satisfying spending and unlock invariants, with no spawning changes enabled.

### Phase 3 — explicit spawning and scheduler

Refactor spawn entry points to accept a purchased class and cargo. Add scheduler registration, cancellation, bounded retries and structured outcomes. Preserve existing score/AI/unit registration. Ensure infantry can spawn while vehicles wait.

Deliverable: ticket-mode regular vehicles working end to end behind the feature flag.

### Phase 4 — separate-special arrival coordination

Route regular transports, convoys, paradrops and airstrikes through shared admission helpers. Integrate reservations without charging specials tickets or altering selection odds/quantities. Check lock ordering and finite producer tracking.

Deliverable: specials remain separate and cannot race the coordinator into forbidden overlap.

### Phase 5 — verification and playtesting

Run the acceptance matrix below; compare ticket and legacy mode in the same scenarios. Tune prices and timing using logs. Do not raise budgets merely to consume leftovers: package limits and expensive unlocks can intentionally leave tickets unused.

Deliverable: tested defaults and complete English/Polish documentation.

### Phase 6 — enable and release

Enable ticket mode after acceptance. Keep a server-side compatibility toggle for rollback during initial playtesting. Do not allow mid-wave mode switches; snapshot the mode at wave start. Sync mission files, stage only the completed work, commit and push through Sync-ToRepo.ps1 workflow.

## 12. Acceptance criteria

Planner:

- Sum of planned costs never exceeds the rolled budget.
- Wave before S, Never and debug-forced cases have no regular plan.
- Exact boundary checks for all unlocks, integer bounds and player cap.
- No unpriced/missing class, illegal duplicate or disallowed combination.
- Empty catalogue returns immediately with a reason.
- Defector plans use defector prices/classes; late join does not replan.
- Same inputs and random draws reproduce the same plan.

Spawning and lifecycle:

- Purchased class and cargo match actual spawn requests.
- Destruction immediately after spawn does not trigger a refund.
- Partial spawn failure cannot duplicate cargo or crew.
- All retries and waits terminate within their deadlines.
- Delayed purchases prevent premature wave completion.
- Expired/cancelled plans do not keep the wave alive.
- No old-wave spawn after preparation, extraction, defeat or debug transition.
- Arrival reservations cannot leak or oversubscribe under concurrent producers.
- Existing manpower caps still hold; infantry can progress while vehicles wait.

Special separation:

- No special reduces regular tickets or triggers additional regular budget rolls.
- Specials Off leaves regular ticket planning functional.
- Vehicle Never preserves existing vehicle-special restrictions.
- Convoy/paradrop quantity logic remains unchanged in the first release.
- Airstrike, paradrop and combat helicopter overlap follows admission rules.
- Weather, FOB, Officer Hunt and FPV lifecycle continue correctly.

Playtests: waves 5/6/7/10/12/16/20/30 with 1/2/3/4/8 humans, RU and defector cases; Legacy catalogue smoke tests; scenarios combining convoy, airstrike, FOB and FPV. Include low manpower capacity, destroyed carriers, no suitable spawn site and missing addon classes.

Record rolled/reserved/deployed/unused tickets, class list, arrival timings, special types, timeout reasons and peak simultaneous vehicles. Use these to distinguish excessive budgets from underpriced vehicles or special overlap.

## 13. Expected outcome and limits

Early waves get more consistent but modest regular vehicle presence. Later waves receive varied combinations constrained by a common budget and arrival rules. Separate specials retain their identity and can still create harder waves.

This design intentionally does not promise equal total difficulty per wave: independent special intensity, terrain, equipment availability and vehicle addon performance remain important. If playtests show special-driven spikes, address those with a separate special balance pass rather than silently spending regular vehicle tickets on them.
