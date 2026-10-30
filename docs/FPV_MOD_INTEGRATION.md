# FPV integration status — 2026-10-30

Implementation started; the special wave is not implemented or enabled yet.

Read-only inspection of the local uncompressed PBO confirmed `O_UAFPV_OG7V_AP` in the addon preInit class list. Config is binarized; requiredAddons and inherited event handlers still need inspection. Metadata's five-payload description is older than the actual scripts, which also include fibre, net, RPG18 and AKS74 variants.

`UA_fnc_fpv_manualDetonate` requires a living player connected to the UAV. `UA_fnc_fpv_onDestroy` instead requires a local supported UAV and positive hit damage. It checks `UA_FPV_PayloadSwapProtected`, `UA_FPV_Detonated` and spawn-settling state; it creates and immediately triggers a native warhead, then deletes crew and UAV. OG7V currently uses the default `R_TBG32V_F` branch. Damage attribution is not preserved from its supplied instigator argument; the function replaces it with UAVControl state. Do not promise operator kill attribution.

`UA_fnc_fpv_handleDamage` only accepts direct bullet damage and explicitly ignores collisions, splash, fire and non-bullet projectiles. Consequently collision detonation and susceptibility to explosives cannot be inferred from generic Arma vehicle behaviour. Full inherited event-handler inspection and an engine probe are necessary before selecting the attack implementation.

Added server-only `bulwark_fnc_fpvAdapter` with availability, cleanup and native detonation operations, restricted to mission-tagged local drones. Cleanup sets the native protection flag and deletes directly. The adapter does not create a second explosion. It is not yet called from gameplay.

Added `tests/fpvAdapter.sqf`: an idle-session probe for creation, local scripted velocity and cleanup, with native payload protected throughout. It does not test detonation. No Arma process was running during inspection and no engine test was executed. The probe needs a disposable mission with the addon and mission functions loaded, normal loop stopped, and open terrain.

Next gate: inspect config event handlers, run this probe, then test native single detonation and cancellation in an isolated editor session. After that implement validated Altis sites, operator lifecycle, target scoring, drone state machine, wave selection, UI, multiplayer tests and documentation described in FPV_OPERATOR_PLAN.md. These items remain outstanding; the adapter is not a completed modifier.
