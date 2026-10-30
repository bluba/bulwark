# FPV addon integration — 2026-10-30

The source implementation now includes the station, director, wave selection and UI. See [FPV_OPERATOR.md](FPV_OPERATOR.md) for behavior, settings and outstanding engine acceptance. No engine probe has been run.

Read-only inspection of the installed `fpv_ua.pbo` and decoded binary config confirmed CfgPatches `FPV_UA`, `O_UAFPV_OG7V_AP` and `I_UAFPV_OG7V_AP`. Dependencies include Arma data/weapons/drones packages and `cba_settings`.

The config init starts takeoff protection synchronously and schedules `UA_fnc_fpv_droneInit`; Hit invokes `UA_fnc_fpv_onDestroy`. The mission creates and prepares a crewless UAV in one unscheduled block: marks native init completed, supersedes the takeoff-protection generation, clears spawn settling, and retains payload-swap protection until a validated attack commit. This prevents the delayed native callback from rearming mission drones. A failed preparation deletes the object.

`UA_fnc_fpv_manualDetonate` requires a connected player and is not used. `UA_fnc_fpv_onDestroy` requires a local supported UAV and positive hit damage; it respects protection/settling and native detonation flags. The OG7V branch creates and triggers `R_TBG32V_F`, then deletes the UAV. Its instigator is derived from UAVControl, so operator kill attribution is not guaranteed.

Inherited HandleDamage accepts direct bullets but ignores collision, splash, fire and non-bullet damage. The mission's Hit handler records interception, while native payload protection suppresses an explosion. Cleanup deletes directly with protection still set. Only the adapter's guarded native detonation operation arms the payload; no second warhead is created by mission code.

`tests/fpvAdapter.sqf` probes crewless creation, velocity and cleanup. `tests/fpvOperator.sqf` exercises production lifecycle and targeting policy. Static inspection does not establish flight stability, damage behavior, multiplayer replication or native detonation correctness; test these in Arma before treating this as gameplay-accepted.

FPV validation update (2026-10-30): user RPT confirms station activation, physical flight, visibility loss, random search, reacquisition, Attack and native detonation success callback. Visual blast/damage, final deletion, dedicated multiplayer and automated harnesses remain unverified. See [FPV_OPERATOR.md](FPV_OPERATOR.md#review-and-observed-engine-results--2026-10-30) for evidence and review fixes; this supersedes earlier statements that no engine evidence exists.

Latest FPV review: fixed close-range reaction-delay bypass and Zeus body-distance audio culling. Terminal commitment and the attack buzz still need engine acceptance; the previously logged successful detonation predates them. See [FPV_OPERATOR.md](FPV_OPERATOR.md) for current behavior and targeted retests.
