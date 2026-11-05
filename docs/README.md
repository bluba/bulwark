# Bulwark Fixed — start here

This directory is the documentation entry point for continuing work on the recovered Arma 3 cooperative scenario. Current source: **dynamicBulwarks.Altis**, the parent of this directory. Documentation updated 2026-11-01. Earlier records use the historical source name Altis.bulwarkFixed.

## Current implementation

[Current state](CURRENT_STATE.md) summarizes the enabled ticket-based vehicle system, +30% player scaling, budget-only model eligibility, separate specials, current shop supplies and verification limits. See the [repository README](../README.md) for setup and overview, and [vehicle implementation](VEHICLE_TICKETS.md) for settings and prices.

## Read in this order

1. [Handoff and current status](HANDOFF.md) — authoritative baseline, user decisions, what is verified, and next work.
2. [Scenario overview](SCENARIO.md) — gameplay and configuration.
3. [Code architecture](ARCHITECTURE.md) — startup, directory responsibilities and ownership.
4. [Waves and enemy AI](WAVES_AND_AI.md) — selection, capacity queue, task controllers and important invariants.
5. [Development and validation](DEVELOPMENT.md) — local commands, engine tests and debugging.

## Implemented feature slices

[Shop first pass](SHOP_REWORK.md) adds clear personal/team balances, a contained layout, remembered selections, catalogue-wide search, server purchase feedback and recent purchases on every tab. Static checks passed; Arma acceptance remains pending.

[Shop Debug tab](DEBUG_SHOP.md) provides host/admin **Kill all enemies** and **Force selected special** controls for all 16 implemented specials. Forcing ends the current wave and starts the selected one through the normal mission loop. Source checks passed; UI/multiplayer acceptance remains pending.

[Thunderstorm special wave](THUNDERSTORM.md) adds heavy rain, lightning and occasional nearby ground strikes from wave 5 onward. Source checks and an unrun engine harness accompany the implementation; multiplayer acceptance remains pending.

| Feature | Current source behavior | Validation |
| --- | --- | --- |
| [F01 ready vote](READY_VOTE.md) | Strict majority; minimum preparation and shared final countdown; live eligibility and phase-bound requests. | Static checks passed; Arma acceptance pending. |
| [F09 recurring FOBs](FIXES.md#f09-recurring-fobs) | Eligible from wave 7 onward; singleton setup and two intervening waves by default. New variants deferred. | Static checks passed; Arma acceptance pending. |
| [F12 tactical coordination](TACTICAL_STATUS.md) | Team status board and four expiring manual pings; English/Polish labels. Support charges deferred. | Static checks passed; Arma acceptance pending. |
| [F15 medical/engineering caches](SUPPLY_CACHES.md) | Supplies shop tab; paid, placeable medical/engineering crates with finite stock. Random spawns and F15 paradrops removed. | Static checks passed; Arma acceptance pending. |

[Feature backlog](FEATURE_BACKLOG.md) tracks implementation scope and remaining proposals. [Feasibility review](FEATURE_FEASIBILITY_REVIEW.md) records costs, integration constraints and delivery gates. Source implementation does not mean gameplay acceptance has passed.

[F15 implementation plan](F15_IMPLEMENTATION_PLAN.md) records the first medical-cache family's design and outstanding acceptance checks; [SUPPLY_CACHES.md](SUPPLY_CACHES.md) describes its source implementation.

[Engineering cache plan](ENGINEERING_CACHE_PLAN.md) preserves the earlier extension design. The current engineering crate is a paid, placeable purchase; see SUPPLY_CACHES.md for its stock and validation. In-game acceptance remains pending.

[Officer Hunt](OFFICER_HUNT.md) implements an officer command post, bounded reinforcement teams, a search objective and owner-local cleanup. Source checks passed; Arma acceptance remains pending. The [implementation plan](OFFICER_HUNT_IMPLEMENTATION_PLAN.md) preserves the design and acceptance cases.

## Existing records

| Document | How to use it |
| --- | --- |
| [FIXES.md](FIXES.md) | Cumulative change record; later sections supersede earlier implementation details. |
| [BASELINE_REVIEW.md](BASELINE_REVIEW.md) | Historical pre-fix findings. Original line numbers are not current. |
| [SPECIAL_WAVES_REVIEW.md](SPECIAL_WAVES_REVIEW.md) | Wave findings, resolved selection issues and remaining concerns. |
| [AI_BEHAVIOUR_REVIEW.md](AI_BEHAVIOUR_REVIEW.md) | Historical AI findings followed by implemented resolutions and validation limits. |
| [WORKSHOP_README.md](WORKSHOP_README.md) | Original README from the recovered Workshop scenario; historical claims/dependency list. |
| [LEGACY_README.md](LEGACY_README.md) | Original README from the older root source; retained separately even where content matches. |

All six existing Markdown files were moved here. The two files originally named readme.md were given distinct names to preserve both originals. New documentation describes the current source; historical reviews are evidence, not a list of still-unfixed bugs.

## FPV Operator source implementation (2026-10-30)

Station lifecycle, bounded crewless drone director, target fairness/cover checks, optional-addon wave selection, Debug entry and PL/EN HUD/search area are implemented. See [FPV_OPERATOR.md](FPV_OPERATOR.md) and [addon integration](FPV_MOD_INTEGRATION.md). Fixed settlement candidates supplement explicit sites/markers; they are not editor-verified navigation points. Static checks passed; the adapter/lifecycle harnesses and in-game multiplayer/flight/detonation acceptance remain unrun.
