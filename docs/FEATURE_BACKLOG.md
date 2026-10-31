# Dynamic Bulwarks — feature and mechanics backlog

**AA crate implemented (2026-10-31):** Supplies entry 9005 costs 6,000 personal points: three ready-to-fire PSZ Groms, three ready-to-fire CUP Iglas, two carryall backpacks, four white smoke grenades and one pair of binoculars. Both installed launchers are CBA disposables; the approved Grom revision gives three shots instead of one launcher with unusable spare missiles. There are no loose AA missiles. Ordinary finite-stock carry/place/move behavior applies. Missing content/disposable support, incompatible firing ammunition or insufficient crate capacity rejects the purchase without charge. In-game equipment/firing and multiplayer placement checks remain pending.


**Approved AT crate implemented (2026-10-31):** Supplies entry 9004 costs 6,000 personal points: two PSZ RPG-7V launchers, six `PSZ_PG7VR_THEAT` tandem-HEAT rounds, one PSZ Spike LR, two `PSZ_Spike_THEAT` missiles, two carryalls and four white smoke grenades. Normal finite-stock placement; no delivery/refill/expiry. Both launcher/ammunition pairs are checked against loaded compatible magazines before payment. Missing classes, incompatible ammunition or insufficient crate capacity reject the entire purchase without charge. PSZ in-game firing/placement tests remain pending.


**Drone supply shop revision (2026-10-31):** the FPV drone supply crate is also in Supplies (ID 9003), costing 3,000 personal points. It retains the former FPV supply drop's complete fixed kit, including packed drone/component magazines, four UAV terminals, two toolkits and four carryall backpacks. Normal carry/place/move controls apply; no paradrop or communications token. The old FPV support entry/dispatch is removed and legacy drone-delivery calls are disabled. Required missing mod content or insufficient capacity rejects the purchase without charge. Standard ammo Supply Drop remains unchanged.


Prepared and updated: 2026-10-29. Status: implementation backlog; entries distinguish source implementation from pending gameplay acceptance.

Implementation tracking: F01 skip-only, F09 recurring existing FOBs, F12 status board plus manual tactical pings, and F15 medical caches are implemented in source. Static checks passed; Arma regression and multiplayer/UI acceptance remain pending. The F15 engineering-cache extension is also implemented in source; its in-game acceptance is pending. New FOB variants, vote extensions and support-charge availability remain deferred. Other entries remain proposals unless marked otherwise.

Feasibility reviewed: 2026-10-29. Read [FEATURE_FEASIBILITY_REVIEW.md](FEATURE_FEASIBILITY_REVIEW.md) before estimating implementation. It rates all 24 features, identifies current-code blockers and narrows first-release scopes. The ratings are static assessments, not in-engine validation.

Cost/benefit ranked: 2026-10-29. Ranking appikjuuuuuuuuuuuuuuuuuuu]\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\lies to the explicitly scoped first version, includes required integration work, and supersedes the earlier milestone order.

## 1. Goal and recommended direction

Expand the existing cooperative scavenge/build/defend mission with more decisions, teamwork and replayability. Preserve its mobile Bulwark, Arma combat, scavenged equipment and escalating attacks. Prefer variation in objectives, timing and enemy composition over simply increasing enemy numbers or accuracy.

**Source implemented; gameplay acceptance pending:** later-wave eligibility for existing FOBs (F09), a ready-to-skip vote (F01), the team status board with manual pings (F12), and finite medical caches (F15). Run their regression and multiplayer acceptance checks. Next unimplemented first slices by value are one supply objective (F03) and better special combinations (F08). F15's engineering cache is implemented as a separately scored extension; its lifecycle/UI cost is not included in the medical slice's score. Prototype heavy AI, extraction and persistence work only after the simpler improvements are tested.

This is a scenario-development backlog. Most proposals can start as mission scripts and configuration; additional addons should be optional. It does not propose copying another game's assets or implementation.

## 2. Simple cost/benefit grading

Scores are engineering/design judgments based on the feasibility review, not measured player outcomes or calendar estimates. **Value = gameplay benefit / implementation cost. Higher is better.** Sort by that ratio; break ties with lower cost first, then practical readiness/reuse. Stable feature IDs do not indicate rank.

| Score | Gameplay benefit | Implementation cost, complexity and change surface |
| --- | --- | --- |
| 1 | Small convenience or mostly development value | Small local change; existing mechanics/state reused |
| 2 | Noticeable but situational value | A few connected scripts/UI changes and bounded multiplayer state |
| 3 | Useful recurring choice or teamwork improvement | Several systems, new authoritative state or a targeted refactor |
| 4 | Strong recurring effect on variety, pacing or cooperation | Substantial subsystem integration, multiple failure paths and broad testing |
| 5 | Potentially changes the core experience | Cross-cutting phase/AI/persistence work with significant prototype uncertainty |

**Value bands:** A = 2.00 or higher (do early); B = 1.25–1.99 (good next candidates); C = 0.75–1.24 (select after the basics); D = below 0.75 (defer unless the group specifically wants it).

The score covers only the **ranked first slice** shown in each card. Deferred extensions are not included in its benefit or cost. Required feature-specific groundwork and multiplayer validation are included; this does not charge every feature for a complete E01–E06 rewrite. Re-score when scope, prerequisites or playtest evidence changes.

An order based on value is not a strict dependency order: complete a required prerequisite first. Minimal diagnostics may accompany any feature even though the player-facing debrief ranks lower. Public-server economy hardening remains separately scoped; the ratings do not imply that the current economy is tamper-proof.

IDs remain stable for implementation references. S/M/L/XL elsewhere indicate relative scope only. The E-items below are enabling work to include with their first consumer, not a mandatory up-front platform project.

## 3. Ranked feature index

The index and detailed cards use the same order. The first three are the cheapest high-payoff changes. Low-ranked features can still suit a particular group; their current benefit does not justify their broader changes as default next work.

Status applies to the ranked first slice in source. **Implemented** does not mean in-game acceptance has passed; deferred extensions remain outside that status.

| Rank | ID | Status | Ranked first slice | Benefit | Cost | Value | Grade |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | F09 | Implemented | Later-wave FOBs | 4/5 | 1/5 | 4.00 | A |
| 2 | F01 | Implemented | Ready-to-skip vote | 4/5 | 1/5 | 4.00 | A |
| 3 | F12 | Implemented | Team status board | 3/5 | 1/5 | 3.00 | A |
| 4 | F15 | Implemented | Placeable supply crates | 4/5 | 2/5 | 2.00 | A |
| 5 | F03 | Not implemented | One optional supply objective | 4/5 | 2/5 | 2.00 | A |
| 6 | F08 | Not implemented | Better special-wave combinations | 4/5 | 2/5 | 2.00 | A |
| 7 | F20 | Not implemented | Milestone reward choice | 3/5 | 2/5 | 1.50 | B |
| 8 | F05 | Not implemented | Basic team rewards | 3/5 | 2/5 | 1.50 | B |
| 9 | F21 | Not implemented | Useful mission presets | 3/5 | 2/5 | 1.50 | B |
| 10 | F02 | Not implemented | Honest next-wave briefing | 4/5 | 3/5 | 1.33 | B |
| 11 | F07 | Not implemented | Distinct enemy loadout packages | 4/5 | 3/5 | 1.33 | B |
| 12 | F13 | Not implemented | Infantry ally orders | 4/5 | 3/5 | 1.33 | B |
| 13 | F22 | Not implemented | Basic debrief counters | 1/5 | 1/5 | 1.00 | C |
| 14 | F04 | Not implemented | Safe defense recycling | 3/5 | 3/5 | 1.00 | C |
| 15 | F10 | Not implemented | One team upgrade | 3/5 | 3/5 | 1.00 | C |
| 16 | F16 | Not implemented | One finite service station | 3/5 | 3/5 | 1.00 | C |
| 17 | F19 | Not implemented | Better individual placement | 3/5 | 3/5 | 1.00 | C |
| 18 | F11 | Not implemented | Reliable support use | 4/5 | 4/5 | 1.00 | C |
| 19 | F06 | Not implemented | Reinforcement pacing | 5/5 | 5/5 | 1.00 | C |
| 20 | F14 | Not implemented | One utility role | 2/5 | 3/5 | 0.67 | D |
| 21 | F17 | Not implemented | Ground extraction finale | 3/5 | 5/5 | 0.60 | D |
| 22 | F18 | Not implemented | Two-position relocation | 3/5 | 5/5 | 0.60 | D |
| 23 | F23 | Not implemented | Optional supply logistics | 2/5 | 5/5 | 0.40 | D |
| 24 | F24 | Not implemented | Intermission checkpoint | 2/5 | 5/5 | 0.40 | D |

## 4. Feature cards in cost/benefit order

Each card starts with its scored first slice and required changes. The design details below it describe the broader feature; they do not expand the scored implementation scope. Apply acceptance cases to the included slice and carry deferred-extension cases into later tickets.

### F09 — Recurring, varied enemy FOBs

**Status (2026-10-29):** ranked first slice implemented in source. FOBs are eligible in primary special selection from wave 7 onward, with at most one active/setup instance and two intervening waves by default (7 -> 10). Configure `BW_FOB_COOLDOWN_WAVES` in `editMe.sqf`. Setup is tracked as a producer; destroyed caches cancel waiting teams and release surviving defenders. Specials Off disables FOBs; vehicle Never does not disable this infantry objective. New variants remain deferred. Static checks passed; `tests/fob.sqf` and multiplayer gameplay checks have not run in Arma. See [FIXES.md](FIXES.md#f09-recurring-fobs).

**Rank 1 · Benefit 4/5 · Cost 1/5 · Value 4.00.**

**Ranked first slice:** Enable the existing FOB on later waves with a cooldown and one-instance limit.

**Required changes / feasibility gate:** Special-selection eligibility and cooldown state; verify cache destruction and spawn cancellation.

**Deferred from this score:** New FOB variants.

**Value:** extend an existing strong mechanic beyond its former waves 7–9 selection window. Inspiration: side operations with tangible combat effects (R5/R7).

**Broader design scope:** first give the existing FOB later-wave eligibility, a maximum concurrent count and a cooldown. Add reinforcement-cache and mortar-position variants later. FOB caches currently block wave completion and are mandatory objectives; preserve that rule unless completion accounting is explicitly redesigned. Destroying the objective ends its stated effect.

**Integration:** `fn_startWave.sqf`, `hostiles/createEmplacement.sqf`, active-objective tracking and guarded spawn requests.

**Accept when:** eligible later waves can select a FOB; its effect stops once destroyed; survivors follow the intended handoff; destroying a cache while production waits at capacity causes no late reinforcement; objective markers and structures clean up.

### F01 — Ready vote and preparation controls

**Implementation status:** Skip-only slice implemented; in-game acceptance pending. Strict majority of living, conscious WEST humans, phase-bound owner-validated requests, live quorum, JIP/respawn self-action and ready counts. Defaults: 15 seconds minimum preparation followed by the final 15-second warning, using one server deadline. See [behavior, settings and validation](READY_VOTE.md).

**Rank 2 · Benefit 4/5 · Cost 1/5 · Value 4.00.**

**Ranked first slice:** Allow a majority to shorten preparation after a minimum delay.

**Required changes / feasibility gate:** Server deadline, phase-bound votes and small HUD control; reconcile the extra start countdown.

**Deferred from this score:** Extensions and advanced voting rules.

**Value:** reduce empty waiting while giving scavengers and new players time to prepare. Inspiration: cooperative preparation around defended objectives (R2); voting details are this proposal.

**Broader design scope:** show ready/eligible counts; allow a majority to shorten intermission, with a minimum preparation period. Offer a limited team-voted extension. Capture eligibility from connected human players; define whether dead spectators vote.

**Integration:** `fn_endWave.sqf`, the start-wave countdown, player HUD and server caller validation.

**Accept when:** one player cannot skip time for a larger team; joins/disconnects recompute quorum; extraction cancels voting; repeated votes cannot start two waves or extend time indefinitely.

### F12 — Shared tactical pings and status board

**Implementation status:** Status board and four manual tactical ping types implemented; in-game acceptance pending. Server-validated reports expire after 45 seconds, with a five-second UID cooldown, one report per author and a 16-report cap. Existing phase/client ticks maintain state and JIP/respawn recovery. See [behavior and validation](TACTICAL_STATUS.md). Support-charge availability remains deferred.

**Rank 3 · Benefit 3/5 · Cost 1/5 · Value 3.00.**

**Ranked first slice:** Show tickets, bank, current objectives and wave state together.

**Required changes / feasibility gate:** Read existing state in the HUD; rebuild display on JIP; no new scanning loop.

**Outside this score:** Tactical pings (now implemented alongside the board). Support-charge display remains deferred until that state exists.

**Value:** support teamwork without requiring everyone to use voice chat. Inspired by readable cooperative objectives (R2/R5); the interface is an original adaptation.

**Broader design scope:** pings for threat, supply, repair and regroup, plus a compact board for tickets, bank, objectives and support availability. Use expiring positions with author labels and per-player rate limits.

**Integration:** client map/HUD, validated server relay and JIP state snapshot. Show localized text labels as well as colors.

**Accept when:** repeated input cannot flood the map; expired pings disappear for everyone; stale corpse positions are cleared; critical information remains readable at supported UI scales; intel restrictions remain effective.

### F15 — Curated supply caches and salvage runs

**Implementation status:** Medical and engineering supply purchases implemented; in-game acceptance pending. Medical stock remains six FirstAidKits and one Medikit subject to loot restrictions. Server-owned transactions validate caller, catalogue price, balance, holding slot, crate class and typed stock/capacity before debit. See [behavior and settings](SUPPLY_CACHES.md) and the [medical implementation plan](F15_IMPLEMENTATION_PLAN.md).

**Current shop behavior (2026-10-31):** medical and engineering crates are bought in a separate Supplies tab for 3,000/3,000 personal points by default. They use normal shop carry/place/move/remove controls and finite native cargo. Automatic spawn rolls and F15 paradrops are disabled; purchased crates have no expiry, wave limit, temporary marker or relocation cleanup. This supersedes the cache/drop lifecycle descriptions below. See [current settings and acceptance](SUPPLY_CACHES.md).

**Delivery tracking:**

**Previous delivery design:** random cache placement and the 2026-10-30 VTOL/parachute revision are retired. Their lifecycle scripts are retained without automatic activation; use the shop transaction/placement acceptance checks instead of the retired delivery harnesses.

| Slice | Source status | Scope / remaining gate |
| --- | --- | --- |
| Medical crate — ranked first slice | Implemented; Arma acceptance pending | Paid finite stock, normal construction placement and native cargo. Run `tests/supplyShop.sqf` in its hosted test environment, then dedicated-server purchase/placement checks. |
| Engineering cache — delivered extension | Implemented; Arma acceptance pending | Paid random mines/grenades and utility stock, typed cargo, normal placement and no refill. [Detailed plan](ENGINEERING_CACHE_PLAN.md). |
| Ammunition caches and salvage rewards | Deferred; not implemented | Tested weapon/magazine compatibility or a separate validated delivery/reward lifecycle, respectively. |

**Engineering contents implemented:** 1–2 random AP mines, 1–2 random AT mines, 1–3 fragmentation grenades, two smoke grenades, one mine detector and one toolkit where native interactions are usable. Apply category caps and existing item/explosive whitelist/blacklist rules before content selection; skip the engineering deployment if neither mine category remains. Demolition charges are a later opt-in addition, disabled in the first engineering slice.

**Engineering purchase behavior:** randomized stock is resolved once per paid purchase. Multiple paid crates may be bought after placement, including in the same wave. Moving/reopening a crate never refills it. Engineering tools use native mechanics; no role trait or new repair service is granted. Engine/multiplayer acceptance has not run.

**Engineering incremental estimate:** Benefit **3/5**, Cost **3/5**, Value **1.00**, Grade **C**. This additional medium-scope change delivered family isolation, typed item/magazine cargo and capacity checks, concurrent placement and multi-cache UI. Its extra acceptance work remains pending. This extension keeps ID F15 and does not inherit the first slice's Grade A or change the 24-feature ranking.

**Rank 4 · Benefit 4/5 · Cost 2/5 · Value 2.00.**

**Ranked first slice:** One purchasable, normally placeable medical crate with finite shared contents; engineering is also implemented as the separately scored extension.

**Required changes / feasibility gate:** Supplies tab/catalogue, validated personal-point transactions, finite typed cargo and the existing normal placement callback are implemented. Verify tab switching, caller ownership, simultaneous requests, movement without refill and persistence. No extra garrison, delivery worker, timer or custom claim reward.

**Outside the first-slice score:** Implemented engineering extension; deferred ammunition families, salvage chains and personalized ammunition refill.

**Value:** make scavenging more purposeful while retaining random loot. Inspiration: optional objectives and discovered resources (R5/R6).

**Broader design scope:** add marked medical, ammunition and engineering caches outside the immediate defense perimeter. Use validated pools, limited charges and distance-based risk/reward. Keep a fallback for towns with few enterable buildings.

**Integration:** `loot/functions/fn_supplyManifest.sqf`, the bounded site selector and start/watch/end supply lifecycle; `missionLoop.sqf`, `fn_startWave.sqf`, F12 map/HUD and `stringtable.xml`. Deployment follows ordinary loot refresh without depending on `loot/spawnLoot.sqf` succeeding. F03 may reuse helpers later; it is not a prerequisite.

**Accept when:** the Supplies tab sells both crates at server-resolved prices; invalid, duplicate-while-carrying, unaffordable or unavailable-stock requests cannot debit points; normal placement/movement preserves contents; wave/truck changes do not remove paid objects; JIP gets the catalogue and remaining native cargo. Validate engineering caps, native tools, friendly mine behavior and inventory concurrency. No automatic cache roll, aircraft, temporary marker or expiry remains active for these purchases.

### F03 — Optional objective catalogue

**Rank 5 · Benefit 4/5 · Cost 2/5 · Value 2.00.**

**Ranked first slice:** Return one marked supply case to the truck for team funds.

**Required changes / feasibility gate:** One objective lifecycle and server-validated reward; reuse F15 placement/content where useful.

**Deferred from this score:** Radio repair, hold-position variants and independent guards.

**Value:** create reasons to leave the truck and split duties. Inspiration: randomized Arma operations (R5) and objective variety (R7).

**Broader design scope:** extend the existing bonus objective into three templates: retrieve a marked supply case, repair a radio under pressure, and hold a temporary observation post. Activate at most one initially. Reward team funds or one support charge.

**Integration:** `bulwark/defendLocationBonus.sqf`, task notifications, event lifecycle and reward service. Give each instance explicit success/failure/cancel states.

**Accept when:** locations are reachable; no objective blocks normal victory unless explicitly mandatory; concurrent completion pays once; timer expiry and extraction clean up owned assets. Solo mode gets suitable distance and interaction time.

### F08 — Structured modifiers and risk contracts

**Rank 6 · Benefit 4/5 · Cost 2/5 · Value 2.00.**

**Ranked first slice:** Add incompatibilities and repetition cooldowns to existing specials.

**Required changes / feasibility gate:** Selection metadata and state cleanup; test current boolean-driven effects before allowing duplicates.

**Deferred from this score:** Risk contracts, voting and new beneficial effects.

**Value:** make stacked specials fairer and give teams agency. Inspiration: warnings/anomalies and extra-risk rewards (R3).

**Broader design scope:** attach tags, incompatibilities, repetition cooldowns and a threat cost to each existing special. Offer a team vote on one optional extra-risk contract, with its reward shown before commitment. Include occasional beneficial conditions, such as surplus ammunition.

**Integration:** replace parallel special pools with a data-driven registry, reusing existing dispatch scripts.

**Accept when:** incompatible combinations never dispatch; weather stays unique; accepted risk pays only on success; rejecting a contract preserves the normal wave; disabling specials clears all optional effects.

### F20 — Team-selected wave rewards

**Rank 7 · Benefit 3/5 · Cost 2/5 · Value 1.50.**

**Ranked first slice:** Vote between bank funds and a known supply crate.

**Required changes / feasibility gate:** Reuse F01 voting; one committed result per milestone; validated grant.

**Deferred from this score:** Support charges until E01 exists and a large reward catalogue.

**Value:** provide a memorable choice after milestone waves. Inspiration: capability progression (R6); the choice system is this proposal.

**Broader design scope:** offer three bounded options, such as bank funds, medical supplies or one support charge. Resolve one team vote with a timeout and deterministic tie rule. Avoid unrestricted weapon escalation.

**Integration:** end-wave state, voting service, reward service and upgrade catalogue.

**Accept when:** one result is committed exactly once; reconnecting cannot repeat a grant; votes do not stall the next wave; unavailable mod-dependent choices are filtered before display.

### F05 — Cooperative contribution rewards

**Rank 8 · Benefit 3/5 · Cost 2/5 · Value 1.50.**

**Ranked first slice:** Add a capped wave dividend and explicit objective contribution credit.

**Required changes / feasibility gate:** Validated completion events, event IDs and reward caps; minimal E04 reward checks.

**Deferred from this score:** Revive, repair and delivery attribution until those paths are proven.

**Value:** make reviving, logistics and objectives rewarding alongside shooting. This is a Bulwark-specific economy proposal, informed by objective rewards (R6).

**Broader design scope:** validated objective rewards and a modest wave-completion team dividend first. Add useful-delivery credit and teammate-revive rewards only after identifying and validating the contributor. Automatic medikit self-revival is not teammate assistance. Show the reason for each award.

**Integration:** `score/functions`, server revive/objective completion and delivery callbacks. Track event IDs, contribution thresholds and per-wave caps.

**Accept when:** self-damage, repeated heal/revive farming and moving the same crate cannot generate unlimited income; legitimate contributors receive credit once; two-client and ownership-transfer tests give consistent totals.

### F21 — Mission presets and reproducible selections

**Rank 9 · Benefit 3/5 · Cost 2/5 · Value 1.50.**

**Ranked first slice:** Offer a few coherent presets with recorded effective settings.

**Required changes / feasibility gate:** Centralize affected direct lobby-parameter reads; clear override precedence and Classic comparison.

**Deferred from this score:** Seeded wave planning and deterministic selection diagnostics.

**Value:** let hosts choose session style and developers reproduce selection problems.

**Broader design scope:** Classic, short-session, tactical-defense and experimental presets. Record resolved settings and use a mission-local selection seed for wave plans, reward options and objective choices. Preserve manual overrides with clear precedence.

**Integration:** `description.ext`, `editMe.sqf`, wave planner and diagnostics. Do not rely on resetting a shared random stream used by unrelated scripts.

**Accept when:** an identical seed/config/input roster reproduces planner decisions; logs include effective configuration; disabled content stays excluded. Explicitly state that physics, combat AI and network timing are not deterministic replays.

### F02 — Next-wave intelligence

**Rank 10 · Benefit 4/5 · Cost 3/5 · Value 1.33.**

**Ranked first slice:** Show committed modifiers and estimated threat tier before combat.

**Required changes / feasibility gate:** Extract a shared wave plan; account for separate vehicle rolls before confirming them; synchronize JIP.

**Deferred from this score:** Approach sectors, exact unit totals and a separate recon progression system.

**Value:** let players prepare for threats instead of discovering every combination through casualties. Inspiration: readable enemy roles (R2) and communicated warnings (R3).

**Broader design scope:** a preparation card with wave number, estimated threat tier and committed modifiers. Generate the upcoming plan before displaying it. Confirm ordinary vehicles only after their separate random selection is moved into that plan. Approach sectors are deferred until producers share a sector/anchor policy; current spawn anchors follow randomly selected conscious players.

**Integration:** move special selection into a server-owned wave-plan step; reuse the result in `fn_startWave.sqf`. Link map sectors and HUD to that plan.

**Accept when:** displayed threats match the executed plan; disabled vehicles never appear as confirmed threats; JIP sees the same plan; no exact hidden unit positions leak.

### F07 — Specialist enemy packages

**Rank 11 · Benefit 4/5 · Cost 3/5 · Value 1.33.**

**Ranked first slice:** Introduce two recognizable packages using existing movement modes.

**Required changes / feasibility gate:** Class/loadout validation, composition limits, gateway integration and LAMBS playtests.

**Deferred from this score:** Sappers, custom spotter behavior and bespoke movement controllers.

**Value:** create tactical counters rather than larger health pools. Inspiration: distinctive Outpost enemies (R2) and pressure on maintained defenses (R4).

**Broader design scope:** add a smoke-covered assault package and a recon/spotter package. Each has recognizable equipment, a warning and a counter. Later consider a sapper targeting eligible defenses and a support team sustaining an attack.

**Integration:** validated class/loadout catalogue, capped package composition, spawn gateway and group-level behavior modes. Avoid independent per-unit movement controllers.

**Accept when:** players can recognize roles; packages cannot silently destroy the Bulwark in Classic; unavailable classes have safe fallbacks; combined specials remain within capacity; threat counters work without a mandatory extra mod.

### F13 — Purchased-ally command menu

**Rank 12 · Benefit 4/5 · Cost 3/5 · Value 1.33.**

**Ranked first slice:** Add hold, patrol and return orders for purchased infantry.

**Required changes / feasibility gate:** Permissions, owner-local dispatch, task cancellation, limits and disconnect fallback.

**Deferred from this score:** Vehicle commands, mixed crews and complex squad management.

**Value:** give purchased allies a clear purpose without constant micromanagement. Extends existing ally patrol/sentry behavior.

**Broader design scope:** defend here, patrol this radius, follow and return to Bulwark. Set per-team/per-player ally limits and display current order. Authorize the purchaser or an explicitly delegated team role.

**Integration:** `fn_activateAlly.sqf`, owner-local command dispatch and tracked task handles. Use one task owner per group.

**Accept when:** order changes stop the previous task; locality transfers do not duplicate it; disconnect has a defined ownership fallback; players cannot command unrelated or Zeus-controlled groups.

### F22 — Debrief and balance telemetry

**Rank 13 · Benefit 1/5 · Cost 1/5 · Value 1.00.**

**Ranked first slice:** Show wave duration, objectives and ending reason.

**Required changes / feasibility gate:** Small server counters and a synchronized ending summary; useful measurement but limited direct gameplay benefit.

**Deferred from this score:** Full contribution analytics and a large reporting UI.

**Value:** reward teamwork visibly and make future balancing evidence-based.

**Broader design scope:** show waves completed, objectives, revives, useful repairs, team spending and extraction result. Record wave duration, incapacitations, hostile peaks, queue waits and support outcomes on the server. Use aggregate counters rather than per-frame event dumps.

**Integration:** score events, producer diagnostics and mission-ending/debrief flow.

**Accept when:** counters reconcile with authoritative transactions; cancelled actions do not count as successes; reports survive ordinary disconnects within a run; telemetry has bounded memory and no unnecessary personal identifiers.

### F04 — Repair, dismantle and recycle defenses

**Rank 14 · Benefit 3/5 · Cost 3/5 · Value 1.00.**

**Ranked first slice:** Refund part of the paid price for approved empty, unoccupied objects.

**Required changes / feasibility gate:** E05 registry/locks, feature-owned actions and atomic removal/refund; test move/dismantle races.

**Deferred from this score:** Repair until class prototypes pass; destroyed-object rebuilding.

**Value:** make engineering useful throughout a run. Inspiration: maintained defenses (R4).

**Broader design scope:** start with deliberate dismantling of approved empty, unoccupied objects for a partial server-calculated refund. Add timed repair only for living classes tested in Arma. Store original price, condition and prior refunds. Destroyed-asset reconstruction is a separate later transaction. Moving an intact object remains distinct from dismantling.

**Integration:** `build/functions`, object purchase metadata, server registry and bank transactions. Replace blanket action removal with removal of feature-owned action IDs; otherwise movement/placement can erase repair and station actions. Begin with a small allowlist of suitable objects.

**Accept when:** repairs consume the correct funds once; refunds cannot exceed the configured fraction of paid cost; cancel/remove/death ends interaction safely; two players cannot repair or refund the same state twice. Crew and inventory follow a documented removal rule.

### F10 — Team-funded Bulwark upgrades

**Rank 15 · Benefit 3/5 · Cost 3/5 · Value 1.00.**

**Ranked first slice:** Buy one session supply-quality upgrade using the bank.

**Required changes / feasibility gate:** Server upgrade state, spending permissions, transaction/UI work and integration with its service.

**Deferred from this score:** Three upgrade trees and medical/intel upgrades without defined services.

**Value:** make the shared bank support strategic choices. Inspiration: field resources funding capability improvements (R6).

**Broader design scope:** three session-only, mutually budgeted branches: medical efficiency, supply quality and intelligence. Start with two levels each. Unlock services rather than unlimited passive damage bonuses.

**Integration:** server bank transactions, upgrade registry, shop and support/intel services. Store upgrades independently of the truck object to support future relocation.

**Accept when:** concurrent buys cannot double-charge or exceed a level; every effect is visible; JIP receives current levels; upgrades reset on a new run; Classic can disable them.

### F16 — Finite medical and resupply stations

**Rank 16 · Benefit 3/5 · Cost 3/5 · Value 1.00.**

**Ranked first slice:** Provide one finite medical service or curated refill station.

**Required changes / feasibility gate:** Asset/action lifecycle, stock accounting, concurrent use and restock rules.

**Deferred from this score:** Universal percentage refill across mod weapons and new revive rules.

**Value:** turn support infrastructure into something worth placing, defending and restocking. Inspiration: maintained defenses (R4); resource rules are proposed here.

**Broader design scope:** one medical station with finite treatment uses or one curated ammunition crate with explicit stock. Replenish through explicit purchases or delivered supplies. Personalized percentage ammunition refill across all mod weapons is deferred until magazine/muzzle compatibility and inventory overflow are tested.

**Integration:** construction catalogue, asset registry, inventory interactions and existing medical conversion. Do not silently replace current medikit revival rules.

**Accept when:** two simultaneous users cannot consume the same last use; destruction removes the service; empty stations explain how to refill; inventory grants are owner-local and authoritative; no refill grants incompatible ammunition or duplicate rewards.

### F19 — Fortification presets and placement improvements

**Rank 17 · Benefit 3/5 · Cost 3/5 · Value 1.00.**

**Ranked first slice:** Preview rotation and basic terrain/bounds validity for a small object list.

**Required changes / feasibility gate:** Local preview, server validation, action cleanup and collision/navigation playtests.

**Deferred from this score:** Multi-object presets and claims of guaranteed AI accessibility.

**Value:** make building practical under time pressure. Inspiration: meaningful constructed defense (R4).

**Broader design scope:** preview rotation and snapping, collision/terrain feedback, and small presets such as a firing position or roadblock. Charge atomically for the whole preset or show a partial-placement policy before purchase.

**Integration:** build pickup/place/drop functions, server catalogue and asset registry. Prefer small object counts and engine pathfinding over scripted enemy obstacle overrides.

**Accept when:** invalid placement has no charge; previews do not become permanent network objects; preset cancellation leaves no orphan pieces; object limits are enforced; common infantry routes remain usable in test layouts.

### F11 — Support charges, cooldowns and delivery feedback

**Rank 18 · Benefit 4/5 · Cost 4/5 · Value 1.00.**

**Ranked first slice:** Migrate one delivery support to charges and visible request outcomes.

**Required changes / feasibility gate:** E01 plus scoped lifecycle/asset tracking; audit every grant/refund path for that support and reconcile its menu.

**Deferred from this score:** Migrating every support type and sophisticated cooldown balancing.

**Value:** make existing supports reliable and legible before adding more. This extends Bulwark's current support mechanics.

**Broader design scope:** display charges, cooldown, accepted target and delivery state. Add team limits for expensive simultaneous assets. Define refund/replacement policy for invalid requests, failed spawn and aircraft loss separately.

**Integration:** E01 entitlement ledger, communication menu, support dispatcher and asset registry. Give recon and controllable UAVs explicit lifetime and cleanup policies.

**Accept when:** duplicate activation consumes one charge at most; the HUD follows server state; failure messages identify next action; destruction/timeout removes owned tasks and crew; active recon handles both hostile factions by design.

### F06 — Bounded adaptive wave director

**Rank 19 · Benefit 5/5 · Cost 5/5 · Value 1.00.**

**Ranked first slice:** Prototype fixed spawn pulses, then bounded adaptation.

**Required changes / feasibility gate:** Producer hooks, pending-budget tracking and special integration; measure pressure with E03/F22.

**Deferred from this score:** Guaranteed quiet periods or a full adaptive director in the first prototype.

**Value:** vary the arrival of new reinforcements through attack and reduced-spawn intervals. Existing attackers can keep fighting during those intervals. Inspiration: pacing principles from R1; the proposed metrics and bounds are specific to this mission.

**Broader design scope:** fixed-state pacing first; then optionally adjust spawn intervals using recent incapacitations, living-player count and engagement duration. Keep the wave's total ordinary budget fixed in the first version. Expose director state in diagnostics.

**Integration:** producer timing and wave-plan generation. Continue using `fn_spawnLimited.sqf`; leave group movement with the existing controller/LAMBS.

**Accept when:** limits are never exceeded; spawn pauses preserve outstanding budget/jobs and cannot prematurely complete a wave; no-target and disconnect cases stabilize; no hidden accuracy increase or mid-wave budget inflation occurs; recorded inputs explain transitions. Measure actual combat relief separately; integrating special producers is required before claiming whole-wave pacing.

### F14 — Session roles and utility kits

**Rank 20 · Benefit 2/5 · Cost 3/5 · Value 0.67.**

**Ranked first slice:** Add one optional role tied to an already useful service.

**Required changes / feasibility gate:** Role/respawn state and switch-abuse prevention; requires the underlying repair, intel or medical service.

**Deferred from this score:** Four classes, medical-rule changes and permanent progression.

**Value:** encourage specialization without permanent grind. Inspired by cooperative role differentiation, adapted to the existing medical/build/support systems.

**Broader design scope:** prototype one utility choice tied to an implemented service, then expand to engineer, medic, scout and support. Potential benefits include faster eligible repairs, medical supply efficiency, better advance intel or more efficient supply handling. Define medical benefits around existing automatic revival and incapacitation protection; stabilization is not an assumed new benefit. Keep ordinary weapons available to everyone.

**Integration:** server role state, shop, contribution rewards and interaction services. Begin without extra class-dependent AI abilities.

**Accept when:** solo players can access essential tools; no role is mandatory for mission completion; switching cannot refresh free charges repeatedly; deaths/JIP preserve the chosen session policy; benefits are explained in the UI.

### F17 — Extraction finale

**Rank 21 · Benefit 3/5 · Cost 5/5 · Value 0.60.**

**Ranked first slice:** Call extraction, defend against a finite attack, then assemble.

**Required changes / feasibility gate:** New extraction phase, producer cancellation, eligibility/ticket rules and ending arbitration.

**Deferred from this score:** Aircraft landing, seating and incapacitated-player loading.

**Value:** create a deliberate last stand rather than ending immediately on arrival. Inspiration: varied extraction locations (R7); this timed finale is the proposed Bulwark design.

**Broader design scope:** an optional call/defend/assemble sequence with a displayed timer, a capped final attack and explicit cancellation/retry rules. Use a ground rally point first; aircraft boarding can follow after terrain testing.

**Integration:** `extract.sqf`, `fn_extractionReady.sqf`, mission-ending arbitration and wave lifecycle. Introduce an extracting phase before setting `missionExtract`: that flag currently ends combat eligibility and prevents the spawn gateway from producing a final attack. Define cancellation of ordinary producers and eligibility of finite finale producers explicitly.

**Accept when:** Classic keeps its current all-survivors rule; the new mode explicitly defines unconscious, dead and pending-respawn eligibility; a final assault cannot exceed capacity; success/defeat priority is deterministic; inaccessible landing terrain cannot softlock victory.

### F18 — Relocation and fallback defense

**Rank 22 · Benefit 3/5 · Cost 5/5 · Value 0.60.**

**Ranked first slice:** Move the truck between two tested sites during intermission.

**Required changes / feasibility gate:** Phase transitions, respawn/loot anchors, asset retention and route/site playtests.

**Deferred from this score:** Procedural routes, automatic fallback defense and damageable truck rules.

**Value:** use the mobile truck to create a multi-position operation. Inspiration: Outpost fallback defense (R2) and location selection (R5).

**Broader design scope:** optional player-driven transfer between two curated, tested positions during intermission. Add procedural destination selection, route preview and fallback defense only after that prototype. Decide what happens to placed defenses, inventories and allies before scripting transport. F17 extraction is not a prerequisite.

**Integration:** location selection, spawn anchors, loot, assets, respawn and mission phases. Keep truck damage disabled in the first relocation prototype.

**Accept when:** destinations and routes pass terrain checks; JIP spawns at the current position; old objectives cannot continue producing enemies; no bank/upgrade loss or item duplication occurs; failure to find a valid site leaves the current run playable.

### F23 — Opt-in supply and power logistics

**Rank 23 · Benefit 2/5 · Cost 5/5 · Value 0.40.**

**Ranked first slice:** Deliver one resource to maintain one station.

**Required changes / feasibility gate:** Delivery ledger, service integration, UI, group-size balancing and cleanup.

**Deferred from this score:** Power networks, multiple currencies and a full production chain.

**Value:** give large groups engineering and transport duties beyond firing. This is an original extension of the mission's supply and building systems.

**Broader design scope:** introduce one shared supply resource first. A delivered crate replenishes repair/station capacity. Only later prototype a generator powering a few optional services; avoid a complex grid in the first version.

**Integration:** F04/F10/F16, server resource ledger and object lifecycle. This mode must be independently selectable.

**Accept when:** capture/delivery pays once; moving a crate cannot duplicate supplies; a destroyed generator does not eliminate every recovery option; small teams can disable logistics; the UI explains service outages and restoration.

### F24 — Session checkpoint and resume

**Rank 24 · Benefit 2/5 · Cost 5/5 · Value 0.40.**

**Ranked first slice:** Prototype same-server restoration of wave, bank and upgrades.

**Required changes / feasibility gate:** Storage/schema, restore-before-start ordering, UID mapping, migration and restart tests; full checkpoint expectations remain a major change.

**Deferred from this score:** Full gear/cargo/crew/structure restoration and cross-server persistence.

**Value:** allow long cooperative runs to continue across scheduled server restarts. Extends session progression; not required for the core defense loop.

**Broader design scope:** save only at intermission. Persist a versioned snapshot of effective configuration, wave, team bank, upgrades, approved assets and player economy. Explicitly choose a supported storage backend before implementation. Recreate gameplay state rather than serializing live script handles or object references.

**Integration:** authoritative registries and a dedicated restore phase before accepting normal player requests.

**Accept when:** save/load/save preserves supported state without duplication; invalid/missing classes have migration rules; corrupt saves fail safely; loading cannot repeat rewards; ownership/JIP rebinds correctly; old schema versions are supported or rejected with an actionable message.

## 5. Enabling work

| ID | Priority / scope | Work and reason | Acceptance evidence |
| --- | --- | --- | --- |
| E01 | P0 / M | Add a server-side support entitlement ledger. Buying grants a charge; activation validates and consumes it atomically. Define refund behavior for rejected targets and failed delivery. | An unpurchased or replayed request grants nothing; concurrent activations cannot spend one charge twice; a failed request follows the documented refund rule. |
| E02 | P0 / M | Give every event/producer a common lifecycle: event ID, wave ID, start, completion, cancellation and cleanup. Register pending finite producers before they run. | Extraction/intermission cancels pending work; no delayed spawns, orphan tasks or event-owned markers remain; wave completion sees pending producers. |
| E03 | P0 / M | Add structured diagnostics and recover the validation workflow. Report active/queued hostiles, finite producers, objectives, support assets and task ownership. | A developer can explain a blocked wave from one diagnostic snapshot; validation instructions work from this checkout; engine tests remain explicitly separate. |
| E04 | P0 / M | Verify scoring and AI ownership on dedicated servers and headless clients; route authoritative reward decisions to the server. | The same legitimate kill pays once under tested ownership changes; player/Zeus control is respected; remote requests cannot select arbitrary rewards. |
| E05 | P0 / M | Create a server registry for placed objects and support assets, including owner, cost, lifecycle and cleanup policy. Replace the empty periodic cleanup path with defined behavior. | Repeated placement does not duplicate records; removal clears crew/tasks/actions as applicable; JIP receives current state; cleanup follows explicit retention rules. |
| E06 | P0 / S–M | Add feature flags and versioned configuration defaults. Define Classic as the existing gameplay rules plus validated fixes. | New systems can be disabled independently; missing saved/config fields use safe defaults; Classic does not require new assets or currencies. |

E01 integrates with `score/functions/fn_purchase.sqf`, `score/functions/fn_support.sqf` and support callbacks. E02/E03 integrate with `missionLoop.sqf`, wave start/end, `fn_queueHostiles.sqf` and `fn_spawnLimited.sqf`. E05 integrates with construction, purchases, aircraft and `supports/cleanup.sqf`.

## 6. Delivery order based on value

Use the ranking to select work, then include only the prerequisites needed by that slice. Do not complete every foundation project before delivering gameplay.

| Stage | Selected work | Required groundwork and release boundary |
| --- | --- | --- |
| 1 — Source implemented; gameplay acceptance pending | F09 existing FOB eligibility; F01 skip vote; F12 board and manual pings | Verify FOB lifecycle/cooldown, phase-bound votes, JIP display, ping expiry/caps and UI scales. New FOB variants and support charges remain deferred. The cost score for F12 covers the board-only slice. |
| 2 — Variety from existing systems | F15 medical cache is source implemented; F03 one supply objective and F08 modifier rules remain proposals | Accept medical inventory/placement/cleanup in Arma. Add scoped E02 cancellation and validated rewards where the next objective needs them; no persistent optional garrison or new AI behavior. Engineering is a source-implemented extension with separate acceptance gates; the first-slice cost score still covers medical only. |
| 3 — More team choices | F20 milestone vote; F05 basic team awards; F21 presets | Reuse F01 voting, centralize effective settings and validate reward events. Playtest income after each addition. |
| 4 — Targeted refactors for stronger tactics | F02 briefing; F07 loadout packages; F13 infantry orders | Shared wave plan and owner-local task control where needed. Prototype combinations before expanding behavior. |
| 5 — Select useful extras | F22 basic debrief; F04 recycling; F10 one upgrade; F16 one station; F19 placement improvements; F15 engineering extension (source implemented, acceptance pending) | Choose based on playtest pain points. Engineering's incremental Grade C includes its delivered mixed cargo/two-family lifecycle/UI; native-tool and multiplayer tests remain pending. F22 counters can accompany earlier releases. Construction features require scoped E05 and action ownership. |
| 6 — Larger investments | F11 support migration; F06 pacing prototype | E01 and lifecycle work for supports; producer integration and measurement for pacing. Reliability fixes may move ahead of gameplay ranking when they block play. |
| 7 — Group-specific or optional modes | F14 utility role; F17 finale; F18 relocation; F23 logistics; F24 checkpoint | Implement only after demand is clear and a targeted prototype passes; no dependency on shipping all earlier features. |

**Accept the implemented F09 + F01 + F12 + F15 medical slices in Arma.** Next unimplemented first slices by value are F03 and F08. The engineering-cache extension is source implemented and also needs its separate acceptance gates above. Add basic diagnostic counters as supporting work; the full player-facing analytics feature is not a prerequisite.

**Important dependencies:** F20 reuses voting from F01; support-charge rewards require E01; F02 needs a shared wave plan; construction/service features need feature-owned actions and the relevant E05 registry; F14 needs the service its role improves; F18 does not require F17; F22 basic counters do not require F05. F03 may reuse implemented F15 placement/lifecycle helpers. F15 engineering extends those helpers for mixed cargo and independent families; it does not require F03, F04 repair services or mine-salvage rewards.

## 7. Existing baseline and constraints

Read together with [FIXES.md](FIXES.md), [BASELINE_REVIEW.md](BASELINE_REVIEW.md), [SPECIAL_WAVES_REVIEW.md](SPECIAL_WAVES_REVIEW.md) and [AI_BEHAVIOUR_REVIEW.md](AI_BEHAVIOUR_REVIEW.md). Historical review findings are not all current defects.

Already present in the inspected source:

- Mobile truck-based Bulwark, points, shared bank, construction and purchased allies.
- Loot, medical conversion, revives, tickets and support purchases.
- Stacked specials, enemy FOB caches, combat bonus objectives and extraction.
- Streaming enemy spawning with an active limit of `min(120, 30 + 4 × human players)`; ordinary infantry uses an 80% threshold.
- Group-level movement control and LAMBS integration, cancellation checks and some regression scripts.

Planning constraints:

- Extend these systems rather than introducing competing movement loops or a second economy.
- New hostile units and crews must use the existing capacity gateway. A director must never bypass it.
- Avoid changing existing extraction rules, truck invulnerability or ticket rules unless the relevant optional mode is enabled.
- Use server-owned state and owner-local execution where appropriate. Treat dedicated-server, join-in-progress (JIP), disconnect and headless-client behavior as explicit acceptance cases.
- Existing in-engine regression scripts have not been verified in this review. The validation/build scripts referenced by older documentation are absent from this checkout.
- Required content depends on configured catalogues. Check actual PSZ/CUP/RHS/LAMBS availability; do not assume an additional content pack is installed.

## 8. Comparable designs and sources

These are design references, not promises that their mechanics transfer directly to Arma. Feature cards below describe proposed Bulwark adaptations; all tuning values are initial hypotheses.

| Ref | Comparable solution | Useful pattern | Primary or official source |
| --- | --- | --- | --- |
| R1 | Left 4 Dead | Dramatic pacing, pressure and recovery instead of constant maximum intensity | [Valve: The AI Systems of Left 4 Dead, Michael Booth](https://steamcdn-a.akamaihd.net/apps/valve/2009/ai_systems_of_l4d_mike_booth.pdf) |
| R2 | Insurgency: Sandstorm — Outpost | Defending successive positions, readable specialist enemies and cooperation under limited resources | [New World Interactive: Outpost developer discussion and announcements](https://store.steampowered.com/news/posts/?appids=581320&enddate=1603382516&feed=steam_community_announcements) |
| R3 | Deep Rock Galactic | Separate beneficial/neutral modifiers from hazardous warnings; compensate extra risk | [Ghost Ship Games: update archive, Mutator System](https://www.deeprockgalactic.com/updatesold) |
| R4 | Fortnite: Save the World | Useful constructed defenses that still require players to maintain them and counter threats | [Epic Games: Save the World design discussion](https://www.fortnite.com/news/save-the-world-design-chat-meta-shift?lang=en-US) |
| R5 | Arma 3 — Combat Patrol | Player-selected locations, randomized operations and exclusions for unsuitable approaches | [Bohemia Interactive: MP Combat Patrol](https://community.bistudio.com/wiki/Arma_3%3A_MP_Combat_Patrol) |
| R6 | Helldivers 2 | Field resources and objective rewards feeding team capability upgrades | [Arrowhead: currencies and resources](https://arrowhead.zendesk.com/hc/en-us/articles/12517746921756-What-type-of-currencies-are-in-the-game) |
| R7 | Helldivers 2 | Objective variety and additional extraction locations | [Arrowhead / PlayStation: objective and extraction design](https://blog.playstation.com/2026/08/18/helldivers-2-a-deep-dive-into-the-illuminate-void/) |

## 9. Shared implementation contracts

### State and authority

- Server decides prices, eligibility, rewards, charges, votes and objective transitions. Client requests identify an action/item; they do not provide trusted reward amounts.
- Use unique transaction/event IDs and explicit terminal states. Apply a state change and its payment/reward atomically where possible.
- Replicate compact current snapshots for JIP. Do not replay an unbounded history of temporary actions.
- Give every spawned asset an owner system, originating wave/event and cleanup policy. Permanent-between-wave assets must be declared explicitly.
- Add functions through the existing `CfgFunctions` registration. Remote-execution restrictions need a complete tested function list; changing the current broad policy blindly could break mission/mod integrations.

### Performance and AI

- Preserve the hostile gateway and reservations. Account for crews, defenders, drones and support packages when applicable.
- Keep task ownership at group level. New mechanics must hand off to the existing controller rather than layering rush/stalk/doMove loops.
- Prefer events and bounded polling. Cache terrain/position candidates and avoid scanning every object on every frame.
- Set explicit limits for placed objects, active objectives, friendly AI, projectiles, effects and persistent markers; the hostile cap alone does not control their cost.
- Optional-objective guards still count in the current global hostile completion check. Define expiry/removal/handoff so an optional objective does not accidentally become mandatory. Keep initial optional caches free of a separate persistent garrison.
- Measure a stable baseline on the intended server. Proposed initial performance budget: no more than a 10% drop in median server FPS at comparable load; also inspect low-FPS periods, queue latency and script errors. This is a target to validate, not a measured result.

## 10. Shared test matrix and definition of done

Each implementation ticket must select the applicable cases below and record results. Static structure/reference checks are useful but do not establish SQF compilation, mod compatibility or gameplay correctness.

| Area | Required cases |
| --- | --- |
| Players | Solo; two dedicated clients; four cooperating clients; representative 25-player load; JIP; disconnect during interaction; all humans absent. |
| Ownership | Server-owned AI; headless transfer if supported; player-owned objects; Zeus takeover; return from takeover. |
| Economy | Insufficient funds; exact balance; simultaneous last-item purchases; duplicate/replayed requests; cancellation after reservation; inventory full. |
| Lifecycle | Normal completion; intermission; extraction; defeat; target destroyed while waiting; timeout; two instances of the same event. |
| Environment | Dense town; few enterable buildings; coast/water; steep terrain; invalid road/landing position; missing optional classes. |
| Combinations | Specials off; vehicles Never; suicide + transport; mortar + FOB; fog/night + intel; recon with EAST and RESISTANCE. |
| Performance | Long run, repeated relocation if enabled, saturated spawn queue, object/marker/crew counts before and after cleanup. |

A feature is done when its acceptance cases pass, server/client RPT errors are addressed, default/disabled behavior is verified, player-facing instructions are updated and outstanding limitations are documented. Do not mark engine tests complete from code inspection.

## 11. Balance measurements and unresolved decisions

Measure before assigning final prices, timers or reward percentages:

- Median and longest wave duration, preparation actually used, and time without a meaningful decision.
- Incapacitations and ticket consumption per wave, separated by player count and preset.
- Objective attempts/completions, useful support calls, and engineering participation.
- Points entering/leaving the economy, bank hoarding, recovery after a failed wave objective.
- Hostile peak, capacity wait time, friendly AI/object growth, script errors and server FPS distribution.

Resolve these in the first planning session; defaults below are recommendations, not approved requirements:

| Decision | Recommended starting point |
| --- | --- |
| Preserve arcade abilities or pursue stricter realism? | Keep Classic unchanged; make tactical restrictions a preset. |
| Damageable Bulwark? | Retain invulnerability initially; prototype damage only with a recoverable fallback mode. |
| New currencies? | Reuse points and bank first; add one supply resource only in F23. |
| Progression duration? | Session-only upgrades; persistent power progression outside the initial scope. |
| Who votes? | Connected eligible humans, majority quorum and a displayed deadline; define spectator eligibility explicitly. |
| Heavy support balance? | Charges and concurrency limits before global price increases. |
| Endgame? | Preserve current win options; offer the extraction finale separately. |
| Extra addons? | No new mandatory addon for the first package; optional adapters later. |
| Development order? | Prioritize clarity/cooperation first; use telemetry to justify the director and alternate modes. |

## 12. Ideas to defer

- Permanent statistical power progression: creates veteran/newcomer imbalance and complicates save integrity.
- Full crafting trees and several currencies: add menu work before proving a logistics need.
- Large armies of purchased AI or uncapped automated turrets: raise simulation cost and reduce player agency.
- Enemy health inflation or maximum-accuracy scaling as the main difficulty mechanism: provides fewer tactical decisions than composition and pacing.
- Mandatory simultaneous distant objectives for small teams: can become impossible rather than challenging.
- Destructible truck plus sudden defeat: requires recovery/fallback design first.
- Full-world territorial campaign, economy simulation or seamless active-wave persistence: separate projects after the core loop is stable.

## 13. Implementation ticket template

Copy this for a selected feature; replace proposed values with explicit decisions before coding.

```markdown
### [Fxx] Feature title — first slice

- Status: proposed / ready / implementing / engine testing / complete
- Owner:
- Benefit / cost / value score and ranked first slice:
- Required prerequisites and deferred extensions:
- Player problem and intended behavior:
- Included in this slice:
- Deferred from this slice:
- Dependencies and feature flag:
- Effective defaults / lobby settings:
- Existing files and proposed new functions:
- Server state, request validation and owner-local effects:
- JIP / disconnect / ownership-transfer policy:
- Payment, reward, cancellation and refund rules:
- Asset, task, marker and event cleanup:
- Acceptance cases:
- Static checks and in-engine scenarios:
- Performance measurements:
- Feasibility rating and prototype result:
- Minimum supported engine/mod versions:
- Player documentation updates:
- Results, limitations and follow-up IDs:
```
