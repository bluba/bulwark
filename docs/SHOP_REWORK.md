# Shop first pass — 2026-11-05

The shop now uses one panel with Build, Support, Supplies and host/admin tools.
Personal kill points and the shared team bank have separate, explicit labels.
Deposit and withdrawal retain the existing transfer limits and server handlers.
The open shop refreshes balances and purchase availability every 250 ms.

Each tab remembers its category, search text and selected catalogue item for the
current mission session, including after placement closes the shop. Blank search
uses the current category; nonempty search finds names across all three shopping
catalogues. Clearing search returns to the current category. Matching rows carry
their kind and stable catalogue ID, so filtering cannot change what is purchased.
Long names have full-name tooltips and prices remain separately aligned.

The details panel explains the purchase outcome, cost, remaining personal points
and common unavailability reasons. Three recent successful purchases are visible
on every tab, including Admin. They use the same availability and pending checks
as the main purchase button. Server checks still authorize every purchase.

A pending purchase blocks further shop requests, including after close/reopen.
Server success or rejection clears that state and supplies the status message.
After 20 seconds without a response the UI explains that confirmation is still
pending; it does not automatically retry or assume the transaction failed.
Build/supply placement still closes the shop; lives/support leave it open.
Developer catalogue entries remain unavailable and are omitted from browsing.

## Validation

Source checks passed for changed SQF/config delimiter and string balance, unique
control IDs, control references, and containment of controls inside the panel.
These are not an SQF compiler or an in-game layout test.

`tests/shopNavigation.sqf` exercises actual controls for category selection,
tab/reopen persistence, cross-catalogue search, empty results and recent-button
visibility. It makes no purchases. It has not been run in Arma in this change.

In-game acceptance still required:

- Run the navigation harness on a host and a normal client; check the RPT.
- Check small/normal/large interface sizes and 16:9/ultrawide screens, including
  long item names and supply details. Check keyboard focus, typing and paste.
- Set different personal/bank balances. Buy, deposit, withdraw, earn points and
  have another player transfer points while the shop remains open.
- Buy a building, vehicle, ally, supply crate, support and extra lives. Verify
  correct item, debit, placement/menu outcome, recent history and feedback.
- Try insufficient points, locked support, missing addons, carrying an object,
  disabled supply families and moving out of range just before purchase.
- Rapidly click Buy/recent buttons, close/reopen while pending, and verify one
  transaction and server-confirmed recovery on rejection, including dedicated MP.
- Verify Admin is hidden for normal players and server checks still reject
  unauthorized actions. Banking and recent purchases remain visible on Admin.

Main implementation: `bulwark/dialogNew.hpp`, `bulwark/functions/fn_shop.sqf`,
`fn_shopAvailability.sqf`, `fn_shopResult.sqf`, the existing recent-purchase helper,
and the two server purchase handlers. Existing tab entry points are wrappers.

## Second pass — favourites, Vehicles and Allies

The header now reads Build, Vehicles, Allies, Supplies, Support, Favourites and
Admin (host/admin only). Vehicles and Allies use the existing build catalogue
categories 6 and 7; they no longer appear under Build. Prices, IDs, server purchase
kinds and placement behavior are unchanged. Containers and Static defences keep
their original category IDs despite their new list positions. Buy remains at the
lower left, with recent purchases available on all tabs.

Select an item and use **Save favourite** above its preview. Saved items have a
`*` prefix. **Remove favourite** reverses this, including directly from Favourites.
The Favourites tab lists saved items across all five shopping sections and offers
section filters. Search there searches only the selected favourites section;
other tabs retain catalogue-wide search with readable section labels.

Favourites are personal to the local Arma profile, persisted immediately under
`BW_SHOP_FAVOURITES_V1`. Each key stores purchase kind, catalogue ID and class or
supply family. This prevents a reused ID pointing a favourite at a different
asset. Missing catalogue entries remain saved but are hidden until available
again. Locked or unaffordable items can be saved; normal purchase restrictions
still apply. No favourites or prices are sent as purchase authority to the server.

The navigation harness now covers the new section mappings, retained Build
categories, favourite save/remove, reload on reopening, section/search filtering,
and removal of the final selected favourite. It temporarily writes favourites and
restores them on normal completion. The harness and in-game checks remain unrun.
Also verify persistence after restarting Arma, profile isolation, all seven tabs
at supported interface sizes, and purchase/placement/rebuy from each new tab.
