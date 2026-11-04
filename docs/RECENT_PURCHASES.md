# Repeat purchases

The BUILD tab has a BUY LAST ITEM AGAIN button (tooltip shows current item/price) and an initial recent-item row. The button works without category navigation. Recent rows use the normal PURCHASE button. Successful build, supply and support purchases update a per-client, mission-session history; failures do not. History survives respawn but not reconnect/client restart. Existing purchases made before this update are not reconstructed.

Records contain only [kind, catalogue ID], newest distinct entry first. Names/prices are resolved from current catalogues each time; removed entries are skipped. The normal server purchase handler revalidates all conditions. No price or stock is copied from history.

Extension knobs in client missionNamespace:
- BW_PURCHASE_HISTORY_LIMIT: retained distinct items, default 10.
- BW_RECENT_PURCHASE_COUNT: recent rows shown on opening BUILD, default 1.

Set these on clients during initialization to show more rows without changing purchase routing. The direct repeat button always selects the newest available entry. No polling loop is added.

Validation: eight changed SQF/config lexical checks, registration/call-site review, and a history model covering ordering, deduplication across kinds and bounded retention. Arma UI/runtime not tested here. Acceptance: buy/place a build item, reopen BUILD, repeat; try insufficient points and occupied holding slot; buy a supply/support item; respawn; show three recent rows; remove a catalogue entry and verify it is skipped.

Two quick-buy buttons now occupy the former wide-button row, with a gap. They show the two newest distinct available purchases, latest on the left. Buying the older entry promotes it to the left. Empty slots are disabled; full item names/prices remain in tooltips. History retention and configurable recent-list rows are unchanged. The optional fourth function argument selects a zero-based quick-buy slot (default 0).
The quick-buy row now has three equal-width buttons (IDs 1615–1617), mapped to history slots 0–2. Tooltips retain full names and prices.
