# F15 — purchasable medical and engineering crates

Current behavior (2026-10-31): both crates are ordinary placeable purchases in **Shop -> Supplies -> Supply crates**. This supersedes the former random-cache and paradrop designs. There are no automatic spawn rolls, aircraft, parachutes, temporary cache markers, delivery workers, expiry timers or wave/relocation cleanup for purchased supplies.

## Buying and placing

| Catalogue item | Default personal-point price | ID | Contents |
| --- | --- | --- | --- |
| Medical crate | **1,000** | `9001` | Six FirstAidKits and one Medikit |
| Engineering crate | **2,000** | `9002` | Random 1–2 AP mines, 1–2 AT mines, 1–3 frag grenades, two smoke grenades and one of each allowed tool |

Edit prices in `BULWARK_SUPPLYITEMS` in `editMe.sqf`. The new Supplies tab is independent of the satellite/support-menu unlock. Its catalogue is published for JIP. The existing Supply Drop support in the Support tab retains its normal delivery behavior; only F15 crate purchases changed.

Select a crate, press Purchase, then use the same carry, Drop Object / Place Object, Pickup, movement and Remove Object controls as other shop objects. A player cannot buy another object while already carrying one. Once placed, another paid crate may be bought in the same wave; there is no family singleton or once-per-wave purchase limit.

Contents are resolved once at purchase and held in normal shared inventory. Placing, picking up, moving, reopening inventory, respawning or reconnecting never refills a crate. Empty crates remain usable containers. Purchased crates survive preparation, wave changes and truck relocation. They can be destroyed or manually removed like other purchased objects; removal deletes cargo still inside and grants no refund. Already collected items or placed mines are independent.

## Stock and configuration

- `BW_SUPPLY_ENABLED` / `BW_ENGINEERING_ENABLED`: allow purchases for each family.
- `BW_SUPPLY_CLASS` / `BW_ENGINEERING_CLASS`: default `Box_NATO_Equip_F`; validated inventory ammunition boxes with sufficient configured capacity. Support-box descendants remain excluded from this family to avoid the existing nearby FAK-conversion scan.
- `BW_SUPPLY_STOCK`: default `[["FirstAidKit",6],["Medikit",1]]`; positive integer amounts capped at six/one, with duplicate multiplication prevented.
- `BW_ENGINEERING_AP_POOL`: curated subset of `APERSMine_Range_Mag`, `APERSBoundingMine_Range_Mag`, `APERSTripMine_Wire_Mag`.
- `BW_ENGINEERING_AT_POOL`: curated subset of `ATMine_Range_Mag`, `SLAMDirectionalMine_Wire_Mag`.
- `BW_ENGINEERING_GRENADE_POOL`: curated subset of `HandGrenade`, `MiniGrenade`.
- `BW_ENGINEERING_SMOKE_POOL`: subset of `["SmokeShell"]`, two total when allowed.
- `BW_ENGINEERING_TOOLS`: subset of `["MineDetector","ToolKit"]`, one of each allowed tool. Remove ToolKit if native repairs are unavailable for the actual role/mod setup; purchasing a tool grants no new trait or repair service.
- `BW_ENGINEERING_AP_COUNT`, `BW_ENGINEERING_AT_COUNT`, `BW_ENGINEERING_GRENADE_COUNT`: inclusive integer ranges, default `[1,2]`, `[1,2]`, `[1,3]`, capped at two/two/three respectively.

All stock respects `LOOT_BLACKLIST`. Strict whitelist mode also requires medical/tools in `LOOT_WHITELIST_ITEM`, and mines/grenades/smoke in `LOOT_WHITELIST_EXPLOSIVE`. Modes 0/2 retain only curated candidates. Empty categories do not transfer budget elsewhere. Engineering requires at least one allowed AP or AT mine. If filtering/configuration leaves no usable stock, the transaction fails without payment.

Tools are item cargo; mines, grenades and smoke are magazine cargo. Generation never creates live explosives. Duplicate random selections are aggregated. No additional rifle ammunition, rockets, satchels, IEDs or demolition charges are included. The old chance, lifetime, relocation and delivery settings are no longer shop settings. The legacy automatic-cache entry point now returns false and has no wave-start callers.

## Server ownership and integration

Clients submit only `[player, "supply", catalogueId]` through the existing purchase endpoint. `loot_fnc_purchaseSupply` validates the caller/ownership, living/conscious WEST human near the truck, catalogue ID, positive integer price, family availability, free holding slot, balance, stock, crate class and cargo capacity. Stock resolution, creation, debit and holding reservation execute together without suspension. Failed checks/creation cannot debit points. Mission-ending requests are rejected.

The created object receives normal shop owner/price/radius metadata and `bw_supplyPurchase`, then the existing `bulwark_fnc_receivePurchase` callback starts normal construction placement. It never receives a temporary `bw_supplyCacheId` or enters the legacy cache registries; old temporary-cache guards therefore cannot block its pickup/movement. No new worker refills or removes the crate. Broad existing remote-execution/public-variable transport is not complete malicious-client hardening.

Core files: `bulwark/dialogNew.hpp`, shop-tab/list scripts and `purchaseNew.sqf`; `score/functions/fn_purchase.sqf`; `loot/functions/fn_purchaseSupply.sqf`, `fn_supplyMass.sqf` and the shared manifest helpers; catalogue publishing in `initServer.sqf`. The existing Support and Debug flows remain distinct. Historical cache/delivery code is retained without automatic activation; [medical](F15_IMPLEMENTATION_PLAN.md) and [engineering](ENGINEERING_CACHE_PLAN.md) plans document earlier designs.

## Validation

`tests/supplyShop.sqf` exercises the real server transaction and cargo in an **idle disposable hosted editor**: living conscious WEST host, normal loop stopped, free carrying slot. It temporarily replaces the host's placement callback, restores globals/player points and removes test objects. Covers default prices, exact medical/typed engineering stock, unknown/invalid callers/IDs, holding-slot duplicate protection, empty allowed stock, missing crate class, disabled family, insufficient points, ending rejection, repeated paid purchases and disabled legacy drops. It does not execute the actual placement controls.

The former `tests/supplyCache.sqf`, `tests/engineeringCache.sqf` and `tests/supplyDelivery.sqf` are retired and exit with a message. Their old automatic drop scenarios no longer describe the active feature.

Hosted/dedicated acceptance still required:

1. Open Build -> Supplies -> Support -> Debug repeatedly. Exactly two supply entries appear with correct prices/preview; no duplicate list callbacks or purchases. Supplies work while Support is locked; ordinary build/support/debug actions remain correct.
2. Buy either crate during preparation/combat; carry and place/drop it, reopen inventory, pick it up and move it again. Stock must remain unchanged except actual inventory transfers. Confirm unrelated player actions remain available.
3. Two clients send overlapping requests. Each accepted crate debits its own buyer once; repeating while carrying is rejected. Spoof another player's object/ID or call the supply handler from too far away: no crate or debit.
4. Clear waves, move/replace the truck and wait beyond the former expiry. Purchased crates remain. There are no automatic F15 drops or cache aircraft. The separately purchased Supply Drop support still works.
5. Join/reconnect after placement: catalogue and remaining native cargo are correct. No refill, aircraft, marker or expiry worker appears. Verify mine/detector/tool interactions and friendly damage with the actual mods.

No Arma/SQF runtime is available here; source checks are not compilation or gameplay validation. No PBO is built. The authorized sync/commit/push workflow applies to this change.

Source verification passed for delimiters/strings in 20 changed SQF/config files, three function registrations/references, catalogue IDs/prices and JIP publication, transaction/placement wiring, disabled automatic activation, retired harness guards, localization references and local documentation links. XML parsing/translation placeholders passed. The new hosted regression and actual placement/multiplayer checks have not run.
