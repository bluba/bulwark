# Dynamic Bulwarks — Altis

Cooperative Arma 3 survival mission source for 1–25 players, derived from Dynamic Bulwarks / SMITH Edition and extended with Polish-versus-Russian forces, a mobile Bulwark, construction, team economy and special objectives.

**Current documentation: 1 November 2026.** Source implementation is available; recent vehicle changes have received static checks, not completed Arma multiplayer acceptance.

## Gameplay

Scavenge equipment, earn kill points, build defenses and buy allies, support and supplies. Survive increasingly strong infantry waves while moving with the Bulwark truck. A shared bank, respawn tickets, intermission ready voting and map pings support team play. Optional extraction becomes available after wave 4; a configurable wave limit provides another victory condition.

## Current wave system

- **Infantry:** wave number × hostile multiplier × max(1, humans × team multiplier), rounded down only at the end. Default multipliers are 2 and 0.5; waves 1–2 use hostile multiplier 1. Infantry tiers change at waves 7, 11, 15 and 19.
- **Regular vehicles:** shared ticket budgets replace independent family rolls by default. All valid catalogue models become eligible together at the configured vehicle start wave (default 5); affordability controls selection.
- **Player scaling:** vehicle budget target increases by 30% per human above two, capped at 2×. Targets also grow with wave age and receive a ±20% range before an integer budget is drawn.
- **Main vehicle first:** the first purchase is selected from the upper affordable cost band, then remaining tickets buy support. Package, repetition and simultaneous-arrival limits remain.
- **Specials:** independent of vehicle tickets. Beginner waves 5–6 select civilians, fog or thunderstorm; broader threats appear later. A guaranteed mortar/paradrop/convoy draw begins at wave 17 when eligible.
- **Capacity and scheduling:** existing enemy manpower limits still apply. Aircraft and truck delivery admission is coordinated, pending purchases have deadlines, and finite producers prevent premature wave completion.

See [current vehicle rules and settings](docs/VEHICLE_TICKETS.md), [current-state reference](docs/CURRENT_STATE.md) and [wave/AI architecture](docs/WAVES_AND_AI.md).

## Features

- Mobile base, defense construction, allied infantry/vehicles and paid support.
- Shared bank, server-validated purchases and respawn-ticket handling.
- Majority ready vote with minimum preparation and final warning.
- English/Polish tactical status and manual map pings.
- Separate weather, bombardment, convoy, paradrop, defector and suicide events.
- Recurring enemy FOBs, Officer Hunt and optional-addon FPV Operator objectives.
- Five finite, placeable shop supply crates: medical, engineering, FPV, anti-tank and anti-air. These are purchased supplies, not random cache drops.
- Host/admin Debug shop controls, including forced selection of 16 specials.

## Configuration and use

This is an Arma mission folder, not a standalone program or packaged release. The active workspace is dynamicBulwarks.Altis. Use it as an Altis multiplayer mission source with the required addons loaded.

| File | Purpose |
| --- | --- |
| [description.ext](description.ext) | Lobby parameters, mission configuration |
| [editMe.sqf](editMe.sqf) | Faction, economy, shop and feature settings |
| [hostiles/vehicleSettings.sqf](hostiles/vehicleSettings.sqf) | Ticket mode, growth, player scaling and random spread; loaded each wave |
| [Vehicle catalogue](bulwark/functions/fn_vehicleCatalogue.sqf) | Exact regular vehicle classes, ticket prices and cargo |

Default faction mode is RU vs PL. The content references PSZ, CUP, RHS and LAMBS; FPV Operator additionally requires its supported FPV addon. This is not an exhaustive validated mod preset: consult mission.sqm, current class catalogues and [FPV integration](docs/FPV_MOD_INTEGRATION.md). Missing class checks do not make the full mission vanilla-compatible; Legacy mode only changes selected enemy pools.

Set BW_VEHICLE_TICKETS=false in vehicleSettings.sqf to restore the previous independent vehicle rolls. Vehicles Never disables regular vehicles and the existing vehicle-gated specials. Specials Off clears special selections but still permits regular vehicles. Enemy vehicle tickets are separate from player respawn tickets and shop points.

## Documentation and testing

Start at [docs/README.md](docs/README.md). Detailed guides cover [scenario rules](docs/SCENARIO.md), [supplies](docs/SUPPLY_CACHES.md), [ready voting](docs/READY_VOTE.md), [tactical controls](docs/TACTICAL_STATUS.md), [Officer Hunt](docs/OFFICER_HUNT.md) and [FPV Operator](docs/FPV_OPERATOR.md).

[Development guide](docs/DEVELOPMENT.md) documents engine test prerequisites. Vehicle planner tests are in tests/vehicleTickets.sqf; the active-wave empty-plan regression is tests/vehicleTicketEmptyPlan.sqf. The capacity harness requires an idle server. These engine tests are supplied, but their execution is not claimed here. Gameplay, addon-class behaviour, air delivery and multiplayer/locality acceptance remain pending.

After mission changes, run Sync-ToRepo.ps1 to sync to the configured Git checkout, inspect changes, stage only the relevant work, commit and push. The script preserves Git metadata and does not delete destination-only files. Do not treat a sync as a successful push.

Original credits and historical dependency notes are preserved in [Workshop README](docs/WORKSHOP_README.md) and [Legacy README](docs/LEGACY_README.md).
