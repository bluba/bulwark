# Performance refactor

- Replaced permanent per-defense proximity loops with one server registry/worker. Registration is unique; dead/deleted objects are pruned. Only one bomber snapshot is made every 0.5 seconds during active waves, and no per-defense spatial queries remain. Held objects, ordinary infantry, players and remotely controlled units retain exclusions. A bomber is dispatched at most once in each tick, avoiding duplicate damage requests across overlapping defenses.
- Enemy scoring registration and controller dispatch share one group/member traversal instead of separate allUnits/allGroups traversals. The five-second AI refresh/lease cadence is retained, including Zeus-added units.
- Enemy and revive tick scripts compile once; the empty support-cleanup polling loop is removed. Background ticks stop when the mission loop stops.
- Loot results are private and deduplicated across player search areas; search coverage is unchanged.
- Curator updates during combat send only newly encountered player bodies. UAV loiter settings are no longer reapplied every half-second.

Validation: delimiter/string source checks on seven changed SQF files, targeted singleton/dedup/dispatch checks and Git whitespace validation. The existing aiBehaviour harness now checks completed registration scripts, a live shared worker and duplicate registration prevention. No Arma runtime tests or FPS measurements were performed.

Acceptance: run tests/aiBehaviour.sqf in its documented idle hosted session; compare server script time with 10/100/300 defenses, including no bombers and multiple bombers. Check pickup/re-drop, ordinary enemies, Zeus takeover, deleted defenses and registry restart. Verify loot cleanup with clustered players, AI/HC control, respawn curator access and UAV loiter/control. The outstanding reported vehicle-placement problem is separate and is not fixed by this refactor.
