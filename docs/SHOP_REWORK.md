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
