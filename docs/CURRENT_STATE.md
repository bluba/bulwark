# Current source state — 1 November 2026

This page and the linked feature guides describe the implemented source. Earlier design plans and review records preserve history; they are not proof of current defects or completed gameplay testing.

## Regular vehicles

Ticket mode is enabled. Configuration is in [vehicleSettings.sqf](../hostiles/vehicleSettings.sqf); exact prices are in [vehicleCatalogue](../bulwark/functions/fn_vehicleCatalogue.sqf).

For wave age = wave − ARMOUR_START_WAVE:

~~~text
playerScale = min(2, 1 + 0.30 * max(0, humans - 2))
target = min(30, (3 + 0.75 * age) * playerScale)
minimum = max(2, floor(target * 0.8))
maximum = max(minimum, ceil(target * 1.2))
budget = uniform integer in [minimum, maximum]
~~~

Before the configured start wave (default 5), with Never, or on debug-forced special waves, regular vehicles are suppressed. There are no per-model wave unlocks. Model selection still respects installed public classes, cargo capacity, remaining tickets and composition limits.

The first purchase comes from candidates costing at least ceil(75% of the highest affordable price). Theme and previous-main-vehicle weights choose within this band. Support purchases use remaining tickets. Unspent tickets expire.

First three vehicle-enabled waves permit two packages; later waves four. At most two identical packages and one combat helicopter are selected. Before age 14 there is at most one heavy/combatAir purchase, later two. Regular active limits are one early and two later. These limits remain even though model unlocks were removed.

Specials spend no regular tickets. Conventional aircraft and known truck deliveries share arrival admission; UAVs are excluded. Waiting requests can expire. Actual deployments can therefore be fewer than planned. Cargo is included in ticket price; regular transports carry Level 2/defector troops in fixed headcounts.

Recent fixes: empty plans return immediately; there is no final artificial 25-second delay; boarding is checked; helicopter passengers exit sequentially with drop-position/altitude checks; previous-main tracking records the first deployed purchase instead of the final support purchase. See [implementation details](VEHICLE_TICKETS.md).

## Infantry and specials

Ordinary infantry = floor(wave × multiplier × max(1, humans × teamMultiplier)). Default multiplier is 2, except 1 on waves 1–2; teamMultiplier defaults to 0.5. Fractional player scaling is preserved. At wave 6, 2/3/4/5 players request 12/18/24/30 ordinary infantry. Vehicle crews and extra reinforcements are additional.

| Waves | Ordinary pool |
| --- | --- |
| 1–6 | Level 1 |
| 7–10 | Level 1 + Level 2 |
| 11–14 | Level 2 |
| 15–18 | Level 2 + Level 3 |
| 19+ | Level 3 |

Main special chance is min(100,35+wave) percent, but no main-special selection occurs before wave 5. Waves 5–6 use civilians/fog/thunderstorm. Broader pools begin at wave 7. Conditional modifiers begin at wave 10. From wave 17 an additional mortar/paradrop/convoy draw occurs even if the main roll fails, subject to eligibility. Details are in [Waves and AI](WAVES_AND_AI.md).

Enemy capacity is min(120,30+4×humans); ordinary admission uses 80% of that value. This is simultaneous enemy manpower, not total wave size or total threat cost.

## Other implemented systems

See the [scenario](SCENARIO.md) for mobile Bulwark, extraction, failure conditions, economy and building; [ready voting](READY_VOTE.md) and [tactical status](TACTICAL_STATUS.md) for team coordination. Enemy FOB, [Officer Hunt](OFFICER_HUNT.md), [FPV Operator](FPV_OPERATOR.md) and [thunderstorm](THUNDERSTORM.md) have dedicated lifecycle logic.

[Shop supplies](SUPPLY_CACHES.md) are finite placeable purchases: medical 3,000 points; engineering 3,000; FPV 3,000; AT 6,000; AA 6,000. Former random-cache delivery plans are historical. The standard ammunition Supply Drop remains a separate support.

## Validation status

Recent changes passed targeted static source/delimiter/catalogue checks and Git diff checks. These do not compile SQF or verify engine behaviour. No Arma multiplayer acceptance is claimed. Planner, capacity, transport delivery, cancellation, missing-addon and FPV behaviour require engine testing under each harness's prerequisites.

The [English detailed report](WAVE_SYSTEM_REPORT.md) and [Polish report](WAVE_SYSTEM_REPORT_PL.md) retain old independent vehicle probabilities in their explicitly marked compatibility sections. Use this page and VEHICLE_TICKETS.md for default vehicle behaviour. The [design document](VEHICLE_TICKETS_DESIGN.md) is historical where it specifies per-model unlocks, retries or unimplemented acceptance gates.
