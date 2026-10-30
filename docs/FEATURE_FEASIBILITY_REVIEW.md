# Feature backlog — Arma 3 feasibility review

Reviewed: 2026-10-29. Scope: all 24 proposals in [FEATURE_BACKLOG.md](FEATURE_BACKLOG.md), the current mission integration points, and selected official scripting documentation.

This is a static engineering and gameplay review. No Arma session, dedicated-server benchmark or installed-mod compatibility test was run. Ratings express implementation confidence, not tested functionality.

## Implementation follow-up (2026-10-29)

F01 skip-only, F09 later-wave eligibility for the existing FOB, and F12 board plus four manual ping types are now implemented in source. See [READY_VOTE.md](READY_VOTE.md), [F09 change record](FIXES.md#f09-recurring-fobs) and [TACTICAL_STATUS.md](TACTICAL_STATUS.md). Static source checks passed; engine regression and dedicated-server/UI acceptance are pending. The ratings below remain scope estimates, not proof of tested behavior. F12's low-cost ranked score covers the board alone; adding pings expands that implementation scope. Vote extensions, new FOB variants and support-charge inventory remain deferred.

## Verdict

The backlog is broadly viable as an extension to this Arma 3 multiplayer mission. Existing assets, SQF, mission UI and the current mods are sufficient for the proposed first versions. None inherently requires a new native extension or a new client addon. Custom models, animations, advanced medical integration or external persistence would introduce separate dependencies if selected later.

The main limitation is scope and interaction with existing systems, rather than missing engine capabilities:

- **10 features have a practical first version:** F01, F03, F08, F09, F10, F12, F15, F20, F21 and F22.
- **10 need scope reduction or a targeted prototype:** F02, F04, F05, F06, F07, F11, F13, F14, F16 and F19.
- **4 should remain optional research work:** F17, F18, F23 and F24. These are feasible, but require phase, balance or persistence design before implementation estimates are useful.

The strongest near-term gameplay additions are ready voting, a concise wave briefing, one optional supply objective, recurring FOBs and support feedback. Repair, role specialization and an adaptive director should follow targeted prototypes.

## 1. Findings that change the plan

### High impact: F02 promises information that the current spawners do not plan

`bulwark/functions/fn_startWave.sqf` chooses special modifiers at wave start. `hostiles/createWave.sqf` separately rolls ordinary vehicles and transports. `bulwark/functions/fn_spawnAnchor.sqf` returns a random conscious player's position, and producers request positions as they run. Moving only the special-selection block earlier cannot produce a complete forecast or a stable approach direction.

**Revision:** first display committed modifiers and an estimated threat tier only. Put ordinary vehicles into the same plan before confirming their presence. Defer approach sectors until producers accept a shared sector/anchor policy, validate suitable positions and disclose when circumstances force a fallback. Define when player count is captured for budgeting; do not promise an exact total before that decision.

### High impact: F06 cannot guarantee recovery by pausing new spawns

Existing units keep attacking; mortar, shelling, aircraft and FOB producers have independent behavior. The capacity gateway limits occupancy, not combat pressure. Pausing ordinary infantry does not create a quiet interval when other threats remain active.

**Revision:** describe the first director as pacing *new reinforcements*. Keep pending budgets/jobs visible to wave completion during a pause. Add explicit pacing hooks for applicable special producers later. Measure time under fire and incapacitations, but do not promise recovery or secretly delete enemies to manufacture it. Dynamic Simulation is not a solution for attackers that must move: disabled entities stop moving. [Bohemia: Dynamic Simulation](https://community.bohemia.net/wiki/Arma_3_Dynamic_Simulation)

### High impact: F17 needs an extraction phase before the success flag

`extract.sqf` currently sets `missionExtract = true` on readiness. `fn_waveActive.sqf` then returns false, and `missionLoop.sqf` selects the extraction ending. The existing hostile gateway consequently rejects new final-assault requests after this flag is set.

**Revision:** introduce an `extracting` phase before final success. Decide whether ordinary producers are cancelled or remain active; then define which finite extraction producers can use the shared capacity. Set the success flag only after the finale succeeds. Ground extraction is the first prototype. A helicopter adds seating, incapacitated-player loading, landing and crew-locality problems.

### High impact: F04/F19 need a construction ownership and action cleanup pass

`build/functions/fn_pickup.sqf` removes all actions from the object, while place/drop remove all actions from the caller. New repair/station/role actions attached there could disappear during normal building. Placement adds object actions without a consistent current-state reconstruction path for JIP. `fn_sell.sqf` simply deletes the object; its refund call is commented out.

**Revision:** track action IDs by feature and remove only owned actions. Use a server asset registry and locks for move/repair/dismantle. Start recycling with eligible, unoccupied, empty objects. Do not activate the old refund comment as the implementation. Resolve ownership and permissions for team-built assets, not just the initial buyer.

### High impact: “repair any defense” is not an engine-independent mechanic

The catalogue includes walls, planks, towers, buildings, static weapons and vehicles. Damage, destruction visuals and useful repair behavior require class-specific tests. Do not assume resetting damage restores every destroyed asset and its gameplay state. Current documentation includes an `allowResurrection` option introduced in 2.22; using it requires a declared minimum version and still requires testing the selected classes. [Bohemia: setDamage](https://community.bistudio.com/wiki/setDamage?useskin=vector)

**Revision:** repair only living, tested classes initially; treat wreck rebuilding as a separate replacement transaction. Replacement must rebuild actions, registry identity, inventory policy and associated group/crew references. Do not charge for “repair” on an object whose supported damage state has not changed.

### High impact: medical roles lack a defined benefit under current rules

`fn_handleDamage.sqf` suppresses damage while incapacitated. `revivePlayers.sqf` already triggers medikit/medical-vehicle revival, and intermission revives are automatic. `description.ext` enables the built-in revive system. “Improved stabilization” is therefore not yet a concrete player benefit; revive credit also needs an identified human contributor, which automatic self-revival does not provide.

**Revision:** begin with medical supply efficiency or a clearly defined teammate treatment action. Specify its interaction with automatic medikit consumption. Postpone altered unconsciousness/bleedout rules and any ACE Medical adapter. First reward objective completions and validated deliveries; add human revive rewards after the attribution path is proven.

### Medium impact: optional objectives and mandatory wave blockers must remain distinct

The mission waits for every living EAST/RESISTANCE unit and active FOB cache. Adding guards to an “optional” salvage objective can make those guards mandatory to finish the wave, even if the objective timer expires.

**Revision:** first optional caches have no separate persistent garrison. If guards are added, cancel/delete or explicitly release them into the main wave at objective expiry and disclose the behavior. Existing FOBs are mandatory wave blockers; retain that identity or deliberately change completion accounting. Do not label all F03/F09 content optional.

### Medium impact: fairness and economy cannot be solved solely in new reward functions

The source still initializes `killPoints` on the player, broadcasts balances, and exposes a generic reward entry point. Server purchase checks are useful, but they are not a complete authoritative economy against hostile clients. Support activation lacks a purchased-charge record, and some failure paths currently re-add communication-menu items directly.

**Revision:** use a server-owned ledger for new purchases/rewards and reconcile UI objects as mirrors. Define the supported trust model: ordinary cooperative concurrency correctness versus public-server hardening. E01 must cover all support entry, failure and refund paths, including objective-granted charges. Scope broader economy hardening explicitly rather than claiming that event IDs alone prevent cheating.

### Medium impact: the dependency graph overstates prerequisites in some places and omits them in others

- A read-only status board does not need support charges, scoring repair or a global lifecycle rewrite.
- Basic diagnostics and debrief counts must precede balancing; they do not depend on contribution rewards.
- A later-wave eligibility change for the existing FOB does not require three new objective templates.
- Role utility depends on the actual repair/intel/medical service it changes, not necessarily contribution rewards.
- Reward votes require the voting primitive; support-charge rewards additionally require E01.
- Reliable forecasts and reproducible selections share a wave planner, which is a real prerequisite missing from the original table.

**Revision:** deliver small shared primitives alongside their first consumers. Do not require all six enabling projects to finish before any playable improvement.

## 2. Feasibility for every feature

Ratings: **Practical** = a bounded mission-script implementation is clear; **Conditional** = useful but needs the listed prototype/refactor; **Research** = decide mode rules and prove the core interaction first. Scope estimates include multiplayer integration, not calendar time. All use existing mission/client capabilities unless otherwise stated.

| ID | Rating / revised scope | Feasible first version | Main gate or limitation |
| --- | --- | --- | --- |
| F01 | Practical / M full, S skip-only | Server deadline and one ready vote per player; skip after minimum preparation | Unify the intermission deadline and separate 15-second start countdown. Capture phase ID so late votes cannot affect another wave. Extensions later. |
| F02 | Conditional / M, L with sectors | Show committed modifiers and a threat estimate | Shared plan must include independently rolled vehicle threats. Sector-aware spawning is separate work. |
| F03 | Practical / M per reusable framework + first objective | One marked supply case returned to the truck for a bank reward | Validate a small set of locations; provide timeout/fallback. Full path reachability across arbitrary terrain is not established by selecting a clear position. |
| F04 | Conditional / M recycle, L broader repair | Recycle approved empty/unoccupied objects; repair a short tested list | Action ownership, transaction locks, damage compatibility and occupied-asset policy. |
| F05 | Conditional / M narrow, L all contributions | Objective award and capped wave dividend first | Revives/repairs require reliable contributor attribution and useful-work thresholds; auto-revival is not teammate aid. |
| F06 | Conditional / L | Fixed reinforcement pulses, then bounded adaptation | Pauses must retain outstanding budget; special producers require integration; current attackers continue fighting. |
| F07 | Conditional / M loadouts, L behaviors | Distinct equipment/loadout packages using existing movement | “Spotter” needs a defined effect and counter. Smoke use and target selection require in-engine LAMBS tests; sapper pathing is a later prototype. |
| F08 | Practical / M registry, L with contracts | Modifier metadata, incompatibilities and repetition cooldowns | Integrate existing boolean-driven effects before claiming that repeatable selections stack. Contracts reuse voting and rewards. |
| F09 | Practical / S eligibility, M variants | Permit existing FOB later with a cooldown and one-instance limit | FOB is a required wave blocker. Additional defenders share capacity and may delay ordinary infantry. Variants need separate tested lifecycles. |
| F10 | Practical / M | One session upgrade, such as a finite supply-quality tier | Define who may spend team funds and what medical/intel services actually exist. Three branches are later content, not minimum scope. |
| F11 | Conditional / L for all supports | Charge ledger and clear outcomes for one delivery support | Audit every current menu grant/refund. Use request IDs and a terminal result so failure cannot refund twice. Then migrate remaining supports. |
| F12 | Practical / S board, M pings | Compact read-only state board, then four expiring map pings | Prefer extending current HUD; map pings must respect information visibility. Avoid a separate always-on per-frame scanner. |
| F13 | Conditional / M infantry, L mixed vehicles | Hold, patrol and return for purchased infantry | Existing ally activation assumes server execution; add ownership-aware dispatch. Player group membership and vehicle crews need separate policies. |
| F14 | Conditional / M small utility, L medical changes | One utility role tied to an implemented service | No benefit exists until the underlying mechanic is defined. Bind selection/charge state across respawn and prevent switch-to-refill. |
| F15 | Practical / M | One curated cache family using validated magazines/items | Cap reward and lifetime; preserve usable fallback loot. Avoid separate guards in the initial optional objective. |
| F16 | Conditional / M fixed cargo, L personalized refill | Finite medical or curated ammo crate | A generic “refill 50%” across mod weapons/muzzles/magazine wells is wider work. Start with server-created cargo and explicit stock. |
| F17 | Research / L ground, XL aircraft | Ground rally with one finite capped final attack | New extraction phase, ticket policy and mission-ending arbitration. Prove completion during pending spawns before adding aircraft. |
| F18 | Research / L curated two-site, XL procedural | Player-driven transfer between two validated locations at intermission | Does not require F17. Preserve truck identity, move respawn/loot anchors and define abandoned defense handling. Automatic route validation/fallback defense is later. |
| F19 | Conditional / M individual placement, L presets | Rotation preview and basic bounds checks for a few objects | Terrain/collision checks do not prove AI accessibility. Multi-object placement needs all-or-rollback semantics and object limits. |
| F20 | Practical / M | Vote between bank funds and a known supply crate | Reuse F01 voting; tie/timeout and one result per milestone. Add support charge option only after E01. |
| F21 | Practical / S presets, M seeded planner | Central effective settings and a recorded preset | Numerous scripts read lobby parameters directly; route them through resolved configuration. Reproducibility covers planner selections, not AI or physics. |
| F22 | Practical / S counters, M complete report | Wave duration, objective outcomes, expenditure and failure reason | Ship before F05; add contribution fields later. Persist summary until clients have received the ending/debrief state. |
| F23 | Research / L | One delivered supply resource used by one station | Technically straightforward, but gameplay value depends on group size and avoiding repetitive hauling. Power is a service-enable flag first, not a physical grid. |
| F24 | Research / M economy-only prototype, XL full listed scope | Intermission checkpoint with wave, bank, upgrades and seed | Persistence backend, schema, player identity, inventory scope and restoration order must be chosen. Full asset restoration is much larger than saving counters. |

No rating implies support for every community mod. A separate portable addon usable in arbitrary missions would also need namespacing, initialization/configuration interfaces, packaging and compatibility work; that is outside this mission-specific estimate.

## 3. Concrete implementation boundaries

### Interaction and JIP

Timed repair, recovery and radio actions can use the built-in hold-action function. Its callback supplies the actor and target, but completion must still be validated against the server's object/event state. Version-dependent optional parameters should not be assumed until a minimum Arma version is chosen. [Bohemia: BIS_fnc_holdActionAdd](https://community.bistudio.com/wiki/BIS_fnc_holdActionAdd)

Reconstruct UI/actions from a current state snapshot. Persistent remote calls are not a safe ordered history for joining players: their JIP execution order is not guaranteed. Use idempotent setup and explicit removal/state checks. [Bohemia: remoteExec](https://community.bistudio.com/wiki/remoteExec)

### Multiplayer transactions

Atomic server state changes are feasible; a long aircraft delivery or owner-local inventory grant is not one atomic operation. Model it as `requested -> reserved -> dispatched -> completed/failed/cancelled`, with one terminal result and a defined refund policy. An acknowledgment timeout must not blindly retry a potentially completed inventory grant. For early versions, server-created shared cargo reduces this ambiguity.

### AI and terrain

The current enemy controller is a useful integration point for enemy infantry, but its eligibility check intentionally excludes WEST groups. Do not reuse it unchanged for purchased allies. Extract shared task-lifecycle helpers if useful and keep faction/permission policies separate.

Neither a collision-free placement nor a nearby road proves that AI will reach a target or successfully traverse a composition. Use curated positions/layouts for the first release, bounded retries and a fallback that preserves mission progress. Prototype route/landing behavior on Altis with the installed mods before expanding the supported layouts.

### Persistence

A database extension is not mandatory for a small server-local checkpoint. Arma supports storing variables in `profileNamespace` and writing them with `saveProfileNamespace`; large profiles are discouraged. This suggests a small same-host prototype, subject to verifying the dedicated server's profile and permissions. It does not provide a cross-server database or automatic restoration of mission objects. [Bohemia: Profile](https://community.bistudio.com/wiki/Profile)

Use separate namespaced save slots with mission/schema identity, validate a loaded snapshot, and retain a previous known-good checkpoint. Define what is lost at a checkpoint boundary before expanding from counters to gear, cargo, attachments, crews and structures.

### Performance evidence

The original 10% median-server-FPS target is a preliminary comparison only. A capped median can conceal reduced headroom. Also record low-FPS periods, scheduler delay, queue latency, object/group counts and client UI cost in equivalent scenarios. Test the intended player count on target hardware; there is no static evidence here that 25 players plus the proposed assets will meet that target.

## 4. Revised delivery plan

1. **Accept the implemented package:** run F01 skip-only, F09 recurring FOB and F12 board/ping regression and dedicated-server/UI checks. Add scoped E06 settings, minimal E03 diagnostics or F22 counters only as needed; they are not all implemented by this package.
2. **Honest briefing and new objective:** extract a shared plan for confirmed F02 information; implement one F03 supply objective with a bank reward. Measure the already implemented F09 later-wave eligibility as a separate balance change.
3. **Construction and support pass:** feature-owned actions and E05 registry; recycle-only F04; E01 plus one F11 support migrated end-to-end. Audit economy entry points within the chosen server trust model.
4. **Variety release:** F08 registry, small F07 loadout packages and F15 caches. Add F20 reward choices using the existing vote service.
5. **Prototype before commitment:** test F06 pulses, a repair allowlist, infantry ally commands and a useful medical utility. Expand only if each behaves well in dedicated play.
6. **Optional modes:** independently prototype F17 ground extraction, F18 curated relocation, F23 station logistics and F24 a small checkpoint. None needs to block the normal mission improvements.

Do not implement every feature at once. In particular, more reward sources, cheaper support, station resupply and team upgrades compound each other; measure the economy after each addition.

## 5. Prototype gates

| Prototype | Minimum experiment | Evidence needed to proceed |
| --- | --- | --- |
| Wave planning | Generate one plan before intermission, execute it after joins/disconnects | Confirmed modifiers/vehicles stay consistent; any player-count adjustment is explained and logged. |
| Repair | Test 5 representative approved classes, damaged and destroyed, with two clients | Actual repair behavior, visuals, charged amount, actions and JIP state agree; unsupported classes remain unavailable. |
| Pacing | Pause producers under a full active limit with mortar/FOB present | No premature completion, leaked reservation or catch-up burst; ordinary pauses have a measurable effect on arrivals. |
| Support ledger | Simultaneous activation, invalid target, lost aircraft and caller disconnect | Exactly one consumption and at most one policy-approved refund per request; menu matches ledger. |
| Ally commands | Hold/patrol/return during local ownership changes and Zeus takeover | One active movement task; no orders overwrite player/Zeus control; safe disconnect fallback. |
| Extraction | Start finale during combat with queued hostiles and a paid respawn pending | Explicit eligibility and ending rules; all jobs settle; successful extraction cannot be cancelled by stale defeat state. |
| Persistence | Save, restart dedicated server, load, save again | Stable counters and identities; no repeated rewards; clear rejection of corrupt/incompatible state. |

## 6. Planning recommendation

Proceed with the mission-script backlog using the reduced scopes above. Keep IDs stable and split large entries into implementation tickets rather than treating every feature card as a single change. The companion backlog has been adjusted to remove the strongest unsupported promises and unnecessary prerequisites.

Before calling any feature implementation-ready, record its exact first slice, supported engine/mod versions, state owner, cleanup policy and dedicated-server acceptance scenario. For gameplay prototypes, an observed result in Arma is the release gate.
