# Shop, mobile Bulwark, friendly AI and supports review

Reviewed: 2026-10-29. Scope: the current `dynamicBulwarks.Altis` source.

This is a static review, not an Arma gameplay test. Runtime source was not changed. Findings distinguish definite missing/incorrect code from symptoms that require reproduction in the installed engine and mods. Prior reviews describe historical snapshots; this report follows the active purchase and action paths in this checkout.

**20 findings: 5 P1 and 15 P2.** P1 means a core purchase/mission-control feature can fail or payment can be bypassed. P2 means incorrect UI, AI behavior, multiplayer synchronization or lifecycle handling. These priorities indicate repair order, not observed incident frequency.

## Scope and checks

- Traced the new shop through `purchaseNew.sqf` → `killPoints_fnc_purchase` → client placement → server ally activation.
- Inspected Bulwark/spin-box pickup/drop, object movement/removal, bank UI and relevant respawn/damage paths.
- Traced all currently purchasable support types: recon, paratroopers, CAS, minefield, controllable UAV, supply, mortar and artillery.
- Checked disabled-but-dispatchable support types separately; did not treat them as normal shop offerings.
- Parsed all 133 build catalogue rows: each has nine fields; IDs are unique and contiguous. Found one definite crew-label/crew-flag mismatch: ID 127.
- Consulted official command documentation and upstream LAMBS task source for multiplayer/API semantics. Installed LAMBS compatibility still requires an engine test.
- No engine, SQF compiler or multiplayer test was run. The documented `tools/validate-baseline.cjs` is absent; `supports/cleanup.sqf` is an empty file.

## P1 findings

### S01 — Support activation does not require a purchased entitlement

**Source:** [fn_support.sqf:9](../score/functions/fn_support.sqf#L9), [fn_purchase.sqf:24](../score/functions/fn_purchase.sqf#L24), [CommunicationMenu.h](../supports/CommunicationMenu.h), `description.ext` / `CfgRemoteExec`.

Purchases debit points and add a client communication-menu item. The server activation handler checks caller ownership and whether the player is alive, but does not check or consume a server-side purchased charge. It also accepts the aircraft classname from the request and dispatches powers that are commented out of the current shop. The broad remote-execution mode permits this entry point.

**Impact:** a client can invoke supports repeatedly without buying them, bypass the satellite unlock and request disabled support types. Caller validation alone does not prove entitlement.

**Repair:** maintain server-owned charges keyed by player and support SKU; derive aircraft/type from the server catalogue; atomically validate and consume a charge. Define exactly which failed requests restore it.

**Verify:** with no purchases, issue an activation request for the caller's own unit; expect rejection and no spawned assets. Purchase one charge, submit concurrent duplicate requests, and verify one activation. Repeat while supports are locked and for a disabled type.

### S02 — Paid objects and frozen allies have no failed-delivery recovery

**Source:** [fn_purchase.sqf:49](../score/functions/fn_purchase.sqf#L49), [fn_receivePurchase.sqf:3](../bulwark/functions/fn_receivePurchase.sqf#L3), `onPlayerRespawn.sqf:3`.

The server debits the buyer, reserves `buildItemHeld`, disables purchased AI movement and sends a one-way placement callback. There is no pending-transaction acknowledgement, timeout, refund or disconnect recovery. The callback rejects a response for a previous player body, while respawn merely resets the new body's flag.

**Impact:** disconnecting or respawning before placement completes can leave a paid object at its temporary spawn location, with NPC/crew PATH disabled. The purchase is never rolled back or finalized automatically. Death while carrying also has no server detachment/finalization path.

**Repair:** represent pending placement on the server, bind it to the buyer/object, and finalize through acknowledgement. On death/disconnect/timeout, safely place and activate the asset or remove/refund it according to one explicit rule.

**Verify:** delay the callback, then disconnect or respawn; separately die while holding infantry, a crewed vehicle and a wall. Funds, holding state, attachment and AI must resolve once without manual Zeus intervention.

### S03 — “ZU-23-2 with crew” spawns without crew

**Status:** fixed in source on 2026-10-29. Catalogue ID 127 now has `Has AI = true`, selecting the existing WEST crew-spawn and placement-activation path. ID 128 remains uncrewed. Catalogue structure and flag checks passed; RHS crew composition and combat behavior still require the in-engine check below. The finding description records the pre-fix behavior.

**Source:** [editMe.sqf:2301](../editMe.sqf#L2301), [fn_purchase.sqf:41](../score/functions/fn_purchase.sqf#L41).

Catalogue ID 127 costs 25,000 and is named “ZU-23-2 with crew”, but its `Has AI` field is `false`. It therefore takes the empty `createVehicle` branch, with no crew/group to activate. ID 128 sells the same classname without crew for 18,000.

**Impact:** the more expensive purchase does not provide the advertised NPC gunner.

**Repair:** correct the crew flag and verify the resulting faction/crew seats against the installed RHS class. Keep the empty version as a separate SKU if desired.

**Verify:** buy both entries; the crewed variant must contain living friendly crew and acquire enemies after placement, while the empty variant remains empty.

### S04 — The mission truck has no authoritative carry lock or carrier recovery

**Source:** [moveBox.sqf:9](../bulwark/moveBox.sqf#L9), [dropBox.sqf:9](../bulwark/dropBox.sqf#L9), [moveSpinBox.sqf:9](../bulwark/moveSpinBox.sqf#L9).

The movement scripts immediately attach/detach the target on a client. They do not reserve a server-owned carrier, reject another pickup, integrate with `buildItemHeld`, check that the caller owns the carry session, or recover after carrier death/disconnect. Hiding an action is the only attempted exclusion mechanism.

**Impact:** concurrent pickups can reattach the mission truck to competing players. A stale/foreign Drop action can detach it. Players can also combine Bulwark carrying with normal shop-object carrying because the two paths use unrelated state.

**Repair:** centralize begin/end carry requests on the server, with one carrier/token per object and one carried object per player. Revalidate alive/conscious/distance/occupancy state and implement death/disconnect cleanup.

**Verify:** two clients activate Pickup together; only one obtains the truck. The loser cannot detach it. Death, disconnect and simultaneous shop purchasing must leave a usable, accessible Bulwark.

### S05 — Predator control has no explicit handback after UAV death/removal

**Status:** fixed in source on 2026-10-29. Predator setup now runs on the operator's client through `supports_fnc_beginDroneControl`. A client watcher and explicit death/respawn hooks use the idempotent `supports_fnc_endDroneControl` finalizer. Session IDs reject stale cleanup, and actual controlled-unit/camera checks preserve newer external control. Terminal setup moved to the same client. Added `tests/droneControl.sqf` for real-engine death/deletion and session-replacement cases; it has not been run here. S16's separate asset-lifetime/crew-cleanup issue remains open. The original finding follows for historical context.

**Source:** [fn_droneControl.sqf:31](../supports/functions/fn_droneControl.sqf#L31).

The support remotely changes control and camera to the UAV driver. There is no paired client finalizer that releases remote control and restores the player's camera after destruction, scripted deletion, cancellation or replacement by another support.

**Impact:** the support can leave the player controlling/viewing a dead unit rather than returning to their soldier. Bohemia documents this failure mode and the need to release remote control explicitly in its [Remote Control Tutorial](https://community.bistudio.com/wiki/Remote_Control_Tutorial).

**Repair:** use a client-owned control session with an idempotent finalizer, and coordinate it with the server asset lifecycle. Restore camera/control only if that session still owns them; do not interrupt a newer session.

**Verify:** destroy the UAV while controlled, exhaust its weapons, replace it with another controlled unit, and kill/respawn the operator. The correct active session or player body must retain control, without a stuck camera.

## P2 findings

### S06 — Mobile Drop is broadcast to other players and removed only locally

**Source:** [moveBox.sqf:17](../bulwark/moveBox.sqf#L17), [moveSpinBox.sqf:17](../bulwark/moveSpinBox.sqf#L17), [dropBox.sqf:15](../bulwark/dropBox.sqf#L15).

Pickup broadcasts a Drop action on the carrier to every client. Other nearby players can see/interact with that action because no carrier-only condition exists. Dropping removes only the action on the activating machine, so other clients retain stale Drop entries. Pickup also broadcasts the initiating client's numeric action ID for removal, although local action histories can differ.

**Repair:** install carrier controls only on the carrier's client, store action IDs locally, and derive object Pickup visibility from replicated carry state. Use the server carry token from S04.

**Verify:** carry/drop repeatedly with two clients and a late joiner; nobody else can drop the carrier's truck, and action counts do not grow. See Bohemia's [addAction reference](https://community.bistudio.com/wiki/addAction) for action execution and ID behavior.

### S07 — Construction and mobile actions have inconsistent JIP state

**Source:** [createBase.sqf:58](../bulwark/createBase.sqf#L58), [dropBox.sqf:16](../bulwark/dropBox.sqf#L16), [fn_drop.sqf:15](../build/functions/fn_drop.sqf#L15), [fn_place.sqf:19](../build/functions/fn_place.sqf#L19).

Initial truck/spin-box Pickup actions are persisted for JIP, while subsequent remove/add operations are not. Placed-object actions are broadcast only to current clients and have no JIP rebuild path.

**Impact:** late joiners receive stale initial mobile Pickup actions, including while the object is held, and do not receive the current placement/edit actions on already purchased objects. Current clients and new clients disagree about interaction state.

**Repair:** rebuild local interactions from current server object state, or manage replacement/removal of persistent calls with stable keys. Avoid replaying a history of actions as a substitute for current state.

**Verify:** join while the truck is held and after several drops; inspect an object placed before joining. All clients must expose the same eligible actions. Bohemia describes the relevant synchronization rules in [Multiplayer Scripting](https://community.bistudio.com/wiki/Join_In_Progress).

### S08 — Placing any purchase removes unrelated player actions

**Status:** fixed in source on 2026-10-29. Pickup stores the two temporary placement action IDs locally on the caller. Drop and Place remove only those local IDs and clear the record, preserving disarm and other custom player actions. Source checks passed; the custom-action preservation scenario below still needs an engine run. The original finding follows for historical context.

**Source:** [fn_drop.sqf:11](../build/functions/fn_drop.sqf#L11), [fn_place.sqf:15](../build/functions/fn_place.sqf#L15), `onPlayerRespawn.sqf` disarm actions.

Both placement paths broadcast `removeAllActions` on the caller instead of removing only the two temporary building controls. This deletes the player's custom Disarm Explosive/Disarm Mine actions and any other actions added to that player by mission/mod code.

**Repair:** retain the local IDs of placement controls and remove those IDs only.

**Verify:** add a harmless custom player action, buy/place an item and verify it survives, together with existing disarm actions.

### S09 — Repositioning an active ally does not suspend its AI task

**Status:** addressed in source on 2026-10-29 by the mobile-Bulwark ally controller. Registered allies enter a held state on the next two-second controller update, reset their previous task and disable PATH until placed again. Placement reuses the singleton controller rather than adding another task loop. Held-state and live-combat behavior still need engine verification.

**Source:** [fn_pickup.sqf:7](../build/functions/fn_pickup.sqf#L7), [fn_activateAlly.sqf:6](../bulwark/functions/fn_activateAlly.sqf#L6).

Initial purchases disable PATH until placement. Later Pickup operations only attach the object and remove its actions; they do not stop patrol/waypoints or disable PATH again. An already activated NPC or crew can keep processing movement/combat while attached to the carrier. Placement then resets its task again.

**Repair:** define an owner-local held state for purchased AI; suspend the old task before attachment and restore/rebuild it on valid placement. Preserve prior AI settings rather than assuming defaults.

**Verify:** pick up a patrolling infantry ally and an active crewed vehicle during combat. No old movement task may continue during carry; dropping must resume exactly one intended task. Physical/combat symptoms need an engine run.

### S10 — Ally activation assumes the server still owns the group

**Status:** addressed in source on 2026-10-29. Activation now registers a server dispatcher that targets the current group owner. The owner-local controller checks locality and player/Zeus takeover, tracks a lease and restarts its local session after ownership returns. HC transfer and takeover behavior still require dedicated-server testing.

**Source:** [fn_activateAlly.sqf:6](../bulwark/functions/fn_activateAlly.sqf#L6), [fn_drop.sqf:67](../build/functions/fn_drop.sqf#L67), [fn_place.sqf:72](../build/functions/fn_place.sqf#L72).

Activation always executes on server target 2. It enables AI and calls LAMBS directly, with no group-owner routing or ownership-change recovery. Upstream [taskPatrol](https://raw.githubusercontent.com/nk3nny/LambsDanger/master/addons/wp/functions/fnc_taskPatrol.sqf) and [taskReset](https://raw.githubusercontent.com/nk3nny/LambsDanger/master/addons/wp/functions/fnc_taskReset.sqf) explicitly return without doing their work for a non-local group.

**Impact:** a purchased group transferred to an HC or another machine can fail to receive its new patrol/reset. This is conditional on actual ownership transfer; the initial server-owned purchase does not alone demonstrate failure.

**Repair:** authorize on the server, execute task changes on the current owner, and verify ownership again at execution time. Honor player/Zeus takeover.

**Verify:** transfer purchased infantry to an HC, then reposition/reactivate it. Repeat with Zeus/player intervention. Confirm one task on the owner and no unwanted takeover.

### S11 — Removing a crewed asset omits crew, task and group cleanup

**Source:** [fn_sell.sqf:10](../build/functions/fn_sell.sqf#L10), [fn_purchase.sqf:56](../score/functions/fn_purchase.sqf#L56).

Remove Object only deletes the selected object. It does not inspect its stored `bw_allyGroup`, terminate tasks, remove associated crew or reconcile registry state. Purchased non-infantry groups are not explicitly configured here for deletion when empty. Deleting the vehicle is not an explicit crew/group lifecycle policy.

**Impact:** removal can leave surviving/disembarked or dead crew, empty groups and stale references. Exact vehicle-deletion behavior must be checked for each engine/mod asset.

**Repair:** remove through an authoritative asset finalizer. Identify purchased crew separately from unrelated passengers; never delete a player occupant. Stop owned tasks and clean up groups only when safe.

**Verify:** remove occupied and empty static weapons, a tank and a helicopter; compare crew/group/task counts before and after. Repeat with a player passenger.

### S12 — Friendly-fire Off does not protect players from friendly NPCs

**Source:** [fn_handleDamage.sqf:4](../bulwark/functions/fn_handleDamage.sqf#L4), `description.ext:634`.

The lobby option is labelled Friendly Fire Off, but `_friendly` only matches other human player units. Purchased allies, support paratroopers and their vehicle gunners are excluded, so projectile damage from those friendlies follows the ordinary damage path.

**Repair:** define friendly fire using the intended faction/group relationship and instigator/vehicle fallback, rather than human membership alone. Decide separately whether player-to-friendly-NPC damage should also be suppressed.

**Verify:** with Friendly Fire Off, test player, purchased infantry, purchased vehicle gunner and support paratrooper fire against a player. Repeat with an enemy and with the option On.

### S13 — Invalid minefield target refunds the server's player

**Source:** [fn_mineField.sqf:12](../supports/functions/fn_mineField.sqf#L12).

The support executes on the server but refunds with `[player, "mineField"] call BIS_fnc_addCommMenuItem` instead of targeting `_player` on their client. A dedicated server has no player unit; on a hosted server this refers to the host rather than necessarily the purchaser.

**Impact:** looking at the sky/using an empty target consumes the client's support menu entry without reliably refunding it to the buyer.

**Repair:** return the charge through the server entitlement policy and update only the purchaser's UI.

**Verify:** host and remote client each activate minefield without a target; only the caller retains the charge and neither gains an extra one.

### S14 — Recon instances share markers and accumulate deletion work

**Source:** [fn_reconUAV.sqf:31](../supports/functions/fn_reconUAV.sqf#L31).

All calls share global `hosMrks` and marker names derived only from the hostile object. Each poll appends names without resetting its list. A second recon resets the first one's list, both create the same marker names and either instance can delete the other's markers.

**Impact:** overlapping purchases interfere; marker bookkeeping/deletion work grows with every poll even within one wave.

**Repair:** use one shared recon service with a reference count, or private per-instance names and bounded arrays. Update existing markers and finalize them explicitly.

**Verify:** run two recon powers, destroy only one UAV and confirm the other remains functional. Array/marker count should track current hostiles, not elapsed polls.

### S15 — Recon ignores hostile defectors

**Source:** [fn_reconUAV.sqf:40](../supports/functions/fn_reconUAV.sqf#L40), `missionLoop.sqf:42`.

Recon includes only EAST, while the mission deliberately makes RESISTANCE hostile and requires both sides to be cleared for wave completion. A defector wave therefore hides its relevant enemies from the paid recon power.

**Repair:** share the mission's hostile-side predicate and decide explicitly how friendly converted units and player-controlled hostile units should appear.

**Verify:** compare recon on EAST-only, RESISTANCE-only and combined waves; surviving hostiles must be represented according to the advertised rules.

### S16 — Predator lifetime and cleanup depend on an exact magazine array

**Source:** [fn_droneControl.sqf:39](../supports/functions/fn_droneControl.sqf#L39), [cleanup.sqf](../supports/cleanup.sqf), `initServer.sqf:138`.

Despite the 600-second description, no deadline exists. The loop only checks UAV survival; scripted destruction requires the entire magazine array to equal `["Laserbatteries"]`. Different loadouts/remaining empty magazine entries can prevent this condition. External destruction exits without the same cleanup, and crew/group deletion is absent. The periodic support-cleanup script is empty.

**Repair:** use a deadline, operator/session cancellation and a deliberate usable-ammunition policy. Always finalize vehicle, crew, group, waypoints and client control through one path. Keep this separate from S05's camera/control repair.

**Verify:** wait past 600 seconds without firing; empty the weapons; destroy the aircraft externally; disconnect its owner. No unowned loop/crew/group should remain.

### S17 — Supply ammunition generation is unsafe for empty/zero-capacity pools

**Source:** [ammoDrop.sqf:15](../supports/ammoDrop.sqf#L15), [ammoDrop.sqf:58](../supports/ammoDrop.sqf#L58), `fn_ammoRequest.sqf` per-player jobs.

The ammunition helper samples `CfgWeapons/magazines` without checking for an empty compatible list. Its primary-ammo loop advances only by the selected magazine's configured count and has no iteration cap. A nonempty pool of zero-count entries never progresses; an empty pool produces invalid selections/errors. Mod weapons using other compatibility definitions require special attention. Global `ammoPlayer` and `pWeap` also allow concurrently scheduled per-player jobs to overwrite each other's player/weapon selection.

**Repair:** resolve a validated compatible-magazine pool, filter positive capacities, bound iterations, and keep player/weapon state private per request. Apply the same checks to launcher, handgun and secondary muzzle paths.

**Verify:** test normal rifles, launchers, underbarrel weapons, empty pools and a deliberately zero-count test entry. Run several player jobs concurrently and inspect the delivered cargo and script termination.

### S18 — Shop labels bank funds as personal points

**Source:** [dialogNew.hpp:121](../bulwark/dialogNew.hpp#L121), [fn_updatePointBankAmount.sqf:13](../score/functions/fn_updatePointBankAmount.sqf#L13).

Control 1005 is the value displayed beside POINT. The bank updater writes the truck's `pointBankAmount` into that control. No separate current personal-point value is populated in this dialog, while purchases use the player's `killPoints` balance. The BANK row is an amount-entry field, not a displayed bank balance.

**Impact:** the shop can appear to show enough money while a purchase is rejected, or show too little while the player can afford it. The normal HUD does not repair the mislabeled shop value.

**Repair:** separate personal balance, bank balance and transfer amount controls, and refresh them after confirmed transactions.

**Verify:** use deliberately different personal/bank balances; buy, deposit and withdraw while the dialog remains open. Each displayed balance must match its authoritative source.

### S19 — Every BUILD-tab visit adds more selection handlers

**Status:** fixed in source on 2026-10-29. Both selection handlers are installed inside a guard stored on the dialog display. Repeated BUILD visits repopulate the controls while reusing those handlers, including their SUPPORT branch. Closing/reopening creates a fresh display and installs one new pair. Source checks passed; repeated tab switching still needs the in-engine check below. The original finding follows for historical context.

**Source:** [fn_showBuildItemGui.sqf:23](../bulwark/functions/fn_showBuildItemGui.sqf#L23), [fn_showBuildItemGui.sqf:54](../bulwark/functions/fn_showBuildItemGui.sqf#L54), `dialogNew.hpp` BUILD button.

The BUILD button reruns the same script on the existing dialog. Each run adds new category and item `LBSelChanged` handlers without removing previous ones. One selection can then repeatedly clear/rebuild the item list and update the preview.

**Repair:** register handlers once when the dialog is created, or store/remove their IDs before re-registering. Keep tab population separate from handler setup.

**Verify:** toggle BUILD/SUPPORT twenty times; handler counts and work per category selection must stay constant.

### S20 — Purchased-object lists are client-only and append duplicates

**Source:** [fn_drop.sqf:63](../build/functions/fn_drop.sqf#L63), [fn_place.sqf:67](../build/functions/fn_place.sqf#L67), `createBase.sqf:11`, `initServer.sqf:61`.

The server initializes and broadcasts `PLAYER_OBJECT_LIST` once. Later placement scripts append on the caller's client, without a server transaction or rebroadcast. Repositioning appends the same object again; removal does not delete its record.

**Impact:** the list is not an authoritative inventory of bought/placed objects and grows stale/divergent. The old hostile obstacle consumer is currently disabled, so this does not prove a current enemy-pathfinding failure; it does invalidate registry-based cleanup/limits and future extensions.

**Repair:** update a server-owned unique asset registry through validated placement/removal events, and publish a current snapshot only where needed.

**Verify:** have two clients buy/reposition/remove assets and then join a third client. Server and clients must agree on a unique live-object set, with no duplicate records after repeated placement.

## Additional checks and design gaps — not counted as confirmed defects

1. **Crewed aircraft use ground-style sentry orders.** `fn_activateAlly.sqf` reads `bw_aiRange` but uses it only for infantry. Helicopters, tanks and static defenses all get a SENTRY waypoint at their placement position. The helicopter catalogue ranges of 300 m have no effect. Decide whether air allies should launch/patrol/return, or are intentionally bought parked. Verify actual SENTRY behavior in combat before changing it.
2. **Repositioning by another player has inconsistent ownership rules.** Pickup/Remove actions are exposed to everyone, but ally activation accepts only the original purchase UID. Define shared ownership and disconnect handover; then make edit and activation permissions agree.
3. **Recon creation discards its returned crew/group and creates another crew/group.** `fn_reconUAV.sqf:20–24` calls `BIS_fnc_spawnVehicle`, then `createVehicleCrew`, then creates a group and joins the UAV object. Verify actual crew membership and which group receives LOITER; do not assume a vehicle-object join is equivalent to explicit crew reassignment. The spawn function already returns vehicle/crew/group, as documented by [Bohemia](https://community.bistudio.com/wiki/BIS_fnc_spawnVehicle).
4. **Predator terminal setup executes on the server.** Terminal assignment/connection is not a dedicated client setup/acknowledgement, and the connection result is ignored. Verify the remote operator's actual terminal connection and gunner access; do not use host-only success as proof. [UAVControl documentation](https://community.bistudio.com/wiki/UAVControl) notes the client-local nature of terminal connections.
5. **Paratrooper handoff needs death/disconnect tests.** Troops join `group _player` after deployment with no explicit policy for a caller who died/disconnected during transit. Their Killed gear-removal handler is installed before joining a player group; verify its execution after locality changes. Losing AT backpacks to parachute replacement also needs a deliberate supply policy.
6. **Floating placement calls a ground-placement command afterward.** `fn_place.sqf:17` invokes the same `setVehiclePosition` path as Drop. Check supported structure types on elevated placements before promising that the floating option preserves height.
7. **Initial truck placement uses only 1 m clearance.** The safe-position search in `createBase.sqf:45` was inherited from a smaller-object design. Test the PSZ truck in cramped towns for blocked doors, clipping and usable respawn space.
8. **“Reset Rotation” reapplies the current direction.** `fn_reset.sqf` obtains `getDir` and sets that same direction; it does not record/restore purchase rotation or level pitch/roll. Clarify the intended reset operation.
9. **Preview lookup assumes row = ID − 1.** This happens to hold for the current 133-row catalogue. Removing/reordering entries would make previews use another row or go out of range, although the server purchase correctly resolves by ID. Resolve previews by ID before catalogue edits.
10. **Disabled legacy supports remain callable under S01.** Rage, kart, mind control, teleport and rocket support are dispatched even when absent from the shop. Review their lifecycles only if intentionally re-enabled; do not advertise them as currently purchasable. The unrelated legacy `supports_fnc_supplyDrop` path is registered but not the active purchased supply implementation.

## Suggested repair sequence

1. S01/S02/S03: validate support entitlement; make paid placement recoverable; correct the crewed catalogue entry.
2. S04/S06/S07/S08: authoritative carry state, local action bookkeeping and JIP rebuilding.
3. S09/S10/S11/S12: friendly-AI hold/activate/remove lifecycle, owner routing and consistent friendly-fire rules.
4. S05/S13–S17: control handback, refunds, recon instance ownership and bounded support work.
5. S18/S19/S20: shop values, one-time UI initialization and authoritative asset records.

## Minimum engine regression matrix

| Scenario | Required observations |
| --- | --- |
| Dedicated server + two clients | Separate personal/bank values; simultaneous purchases; delayed callback; remote buyer invalid-target refund. |
| Carry contention | Two pickups on one truck; foreign Drop attempt; carry plus shop purchase; carrier death/disconnect. |
| JIP | Join while truck held; join after repeated drop; join after allies/defenses were placed. |
| Friendly NPCs | Buy infantry, ZU-23 crew, tank crew, helicopter crew and autonomous turret; activate, move and remove each. |
| Ownership | Transfer purchased group to HC; Zeus control/release; player boards a purchased vehicle. |
| Friendly fire | Humans, bought infantry, bought gunners and paratroopers with Friendly Fire On/Off. |
| Support overlap | Two recons; recon during defector wave; two Predator sessions; operator dies/disconnects. |
| Support termination | UAV shot down, ammunition exhausted, 600 seconds elapsed, invalid mine target, extraction during transit. |
| Supply compatibility | Multiple weapon families, underbarrel launcher, empty/zero-capacity test pools and concurrent per-player fill jobs. |
| Long session | Repeated purchase/place/remove cycles; compare live assets, crew, groups, actions, markers and scheduled jobs. |

Record server and client RPT output for these cases. No item in this matrix was executed as part of this static review.
