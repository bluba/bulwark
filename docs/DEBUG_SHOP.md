# Bulwark shop Debug tab

Implemented in source on 2026-10-30. Open **Shop +** at the Bulwark and select **DEBUG** alongside BUILD and SUPPORT. This is a separate button panel, leaving room for additional fixed debug actions.

The first button, **Kill all enemies**, runs the previously supplied command on the server: it sets damage to 1 for currently living, non-player EAST/RESISTANCE units, including vehicle crews. Friendly AI, civilians and player units are excluded. It does not clear infantry budgets, pending producers or queues, destroy FOB caches, force a phase change or stop weather. Suicide-bomber death effects still occur. Further enemies can arrive after the button is pressed. The requester receives the number of units targeted.

Access is limited to the locally hosted server player or an administrator recognized by the dedicated server (logged-in or voted admin). The tab is visible to everyone with explanatory text; its action button is disabled for ordinary clients. The server independently verifies caller ownership, a living conscious player within ten metres of the current Bulwark, and host/admin status. UI visibility is not the authorization boundary. There is no client-supplied script, side list or target list. The action ID is whitelisted; duplicate requests are limited to one per UID every two seconds, with a server RPT audit entry. This endpoint is restricted to server execution in CfgRemoteExec. The mission's pre-existing broad remote-execution policy remains outside this change.

## Reset Zeus

Press **Reset Zeus** beside **Kill all enemies** to restore access when Y only produces the eye notification and ping sound. The server unassigns `mainZeus` and assigns it to the requesting host/admin's current player unit. Close the shop, wait a moment, then press Y. This does not open Zeus automatically or change its editable objects.

The action uses the existing caller/proximity/permission checks and shared two-second cooldown. It remains available during a forced-wave transition. A missing module, another living player owning `mainZeus`, or the requester already owning a different Zeus module produces an explanatory message without changing assignments. A stale corpse assignment can be recovered.

Source checks cover the button ID, visibility/permission wiring, action dispatch, server-only assignment and layout bounds. In-game UI, assignment recovery after respawn and dedicated-admin behavior still require Arma acceptance.

## Force a special wave

Select one of the **16 implemented specials** in the Debug list, then press **Force selected special**. This ends the current wave and advances the normal mission loop to the next wave number with exactly the selected special plus ordinary infantry. It also works during preparation or the start countdown. The normal preparation/countdown, random modifiers and automatic enemy vehicle/transport additions are skipped for that forced wave. Existing automatic supply-cache/delivery rolls remain independent.

The selected special bypasses Specials Off, its vehicle start/Never filter and, for FOB/Officer Hunt, normal minimum wave, feature-enabled flag and cooldown eligibility. The shared active enemy cap, valid settings/classes, safe placement, objective singleton and FOB/officer mutual exclusion still apply. Missing mods, invalid content or failed placement can prevent a special from deploying; forcing does not invent replacement assets. Lobby settings are never rewritten. A forced successful objective deployment still updates its normal cooldown history.

The server accepts only catalogue IDs, refuses extraction/mission-ending requests and admits one transition at a time. The RPC queues the choice; it never launches a second mission loop or calls `startWave` itself. The mission loop closes combat, ends storm/officer/supply events, deletes current hostile AI and enemy-occupied/tagged enemy vehicles, removes FOB caches, clears tracked projectiles and retires the bonus marker. Hostile deletion avoids suicide-bomber death explosions. Friendly units/vehicles and player-occupied vehicles are preserved. It drains finite producer handles and capacity requests before incrementing the wave; extraction still takes priority. No forced-completion bank reward or preparation refill/revive is granted.

Capacity records now retain their producer handle as a fifth, server-local field. Finished producers' orphan tickets can be removed during the transition; live helpers must finish and release their own reservations. Trucks' departure/cleanup delays are cancellation-aware so a force request does not wait through their old 30/60-second sleeps. Slow cleanup is logged every 20 seconds; the mission waits safely rather than resetting a live spawn queue. Existing native effects already in progress and untracked airborne mortar rounds can finish during the transition; the existing mortar-projectile tracking limitation remains open.

The exact `[nextWave, selectedType]` override lasts only for that forced wave. At the following normal wave, random selection and ordinary vehicle settings resume. The normal wave limit can be crossed by an explicit pending force request; after the forced wave clears, ordinary completion rules apply again.

## Source layout

- `bulwark/dialogNew.hpp`: three header tabs and dedicated debug controls. Tab widths fit to the left of the existing points/bank controls.
- `bulwark/functions/fn_shopTab.sqf`: switches visibility for purchase lists/button/preview versus debug controls; `CAT_OPEN = 2` identifies this panel.
- Existing Build/Support population scripts call the shared switch. `bulwark/purchaseNew.sqf` rejects accidental purchase dispatch while Debug is selected.
- `bulwark/functions/fn_requestDebugAction.sqf`: authoritative permission checks, fixed action dispatch, cooldown, enemy kill and feedback. Registered in `bulwark/Functions.hpp`.
- `fn_debugSpecials.sqf`, `fn_debugForced.sqf`, `fn_debugAdvanceWave.sqf`: fixed catalogue, exact wave/type exception and mission-loop-owned cancellation. `fn_startWave.sqf` consumes the override after normal draws and before faction setup/dispatch.

To add another debug button, give it a unique control ID, include it in the shared visibility switch and route a new fixed action ID through the server handler. Do not send arbitrary executable strings or turn debug entries into shop purchases.

## Verification

`tests/debugShop.sqf` is an idle disposable server/editor harness requiring a living host/admin near the Bulwark and no current hostiles. It creates temporary EAST/RESISTANCE/WEST actors and invokes the actual handler to test unknown-action rejection, both hostile sides, friendly/caller survival and cooldown/retry behavior. It restores cooldown state and removes its actors. It has not been run here.

Arma acceptance remains required: switch Build → Debug → Support → Debug repeatedly; close/reopen the dialog; check that debug buttons and ordinary purchase controls never overlap; test supported UI scales; run on a hosted server and dedicated admin client; reject a normal client's direct RPC, forged caller and out-of-range/dead/incapacitated caller; log out as admin while the tab is open and confirm server rejection; kill HC-owned enemy crews; and verify queued reinforcement/FOB behavior matches the button description.

Static verification passed: string/comment/delimiter checks for nine changed SQF/config files; both new function registrations/source files; uniqueness of the three new control IDs; tab/content layout bounds; server caller/admin/action/target/cooldown guard references; and the remote-execution server-target restriction. These are source checks, not SQF compilation or rendered UI testing. No Arma session was run and no PBO was created.

Force-special follow-up checks: lexical structure in 19 changed SQF/config/test files; all 57 Bulwark function files; all 15 unique catalogue keys have dispatch cases; forced selection precedes faction setup; cleanup precedes the next mission-loop start; the RPC has no wave-start call; new UI IDs and content bounds are valid. These remain static checks.

`tests/debugShop.sqf` additionally checks invalid special IDs and single pending transition admission without running another mission loop. `tests/debugForceWave.sqf` exercises actual administrative cleanup with a capacity-waiting producer, an orphan ticket, a tagged empty enemy vehicle and friendly fixtures; it checks queue drainage, preservation and exact next-wave/type scoping. Both harnesses are unrun. In dedicated acceptance, force every special during combat/preparation/countdown, with Specials Off/vehicles Never, at the wave limit and while FOB/officer/transport/artillery producers wait; verify no previous-wave troops appear, all transitions have one start owner and normal random selection resumes afterward.

FPV Drone Operator is the sixteenth entry. It requires the optional Ukraine FPV Drone addon and a valid hidden site even when forced. See [FPV_OPERATOR.md](FPV_OPERATOR.md).
