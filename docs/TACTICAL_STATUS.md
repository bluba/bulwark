# F12: Shared tactical pings and status board

Implemented the ranked status-board slice and the four manual ping types requested alongside it. Support-charge availability remains deferred: the mission has no shared charge inventory to display.

## Player controls

Aim at a ground position and use one of the self-actions **Ping: Threat**, **Ping: Supply**, **Ping: Repair**, or **Ping: Regroup**. Teammates see a colored map marker with the type and author's name. A ping reports a fixed ground position; it never follows an enemy, identifies a target, discovers loot or scans the world. Existing artillery map-click controls are unchanged.

Ping labels, feedback and the board have English fallback and Polish translations. Each client localizes its own display through the mission [Stringtable.xml mechanism](https://community.bistudio.com/wiki/Stringtable.xml); the server stores language-independent kinds and phases.

- Maximum distance from the author: **1,000 metres**.
- One accepted ping per UID every **5 seconds** across all four types.
- Lifetime: **45 seconds**; one active report per author.
- Team limit: **16 reports**; a new report evicts the oldest when full.
- Only living, conscious WEST humans may send reports. Author death, disconnect or side change clears their report; respawn cannot inherit a corpse's marker. Extraction and mission completion clear reports.

The server validates ownership, kind, finite coordinates, map bounds, distance, mission state and cooldown. Cooldown is keyed by UID, surviving respawn/reconnect. Markers render locally only for WEST players; mission snapshots use the existing public-variable infrastructure, not a confidential side-only transport. These are player-supplied reports, not authoritative enemy intelligence.

## Status board

The existing points HUD now also displays wave number, Preparation/Combat/Extraction/Ended state, shared respawn tickets, bank balance, active marked FOB cache count and the current white bonus objective. With no side objective it shows the defense/preparation instruction. The panel expands vertically for wrapped text and uses safe-zone width.

The server reads existing registries and the current bonus marker during existing mission ticks, publishing only changed snapshots. The existing one-second player-action maintenance loop maintains ping actions, local marker expiry and HUD recovery; there is no new polling script, per-frame handler or enemy scan. JIP clients receive current snapshots and filter expired reports immediately. Actions are recreated after respawn/removal without deleting other features' actions. HUD changes reuse the display instead of recreating it on every points update.

## Validation

Run `[] execVM "tests\tactical.sqf"` locally on an idle server with the normal mission loop stopped and a living WEST human connected. The harness exercises real handlers: malformed requests, map/range checks, cooldown, per-author replacement, the team cap, expiry/deleted authors, phase snapshots and extraction cleanup. It restores modified globals. It does not test network ownership or UI rendering.

Hosted and dedicated multiplayer acceptance checks:

1. Two clients: send all four kinds, waiting five seconds between sends. Verify author/type/color, fixed position, replacement and expiry on both maps. Rapid repeated requests must not add markers or refresh expiry.
2. Attempt a request using another client's player object; it must be rejected. Test dead, incapacitated and non-WEST senders. Other sides must not render the map markers.
3. Join while reports exist, then join after expiry. Only current reports should appear. Kill/disconnect the author and respawn: old reports vanish; exactly four actions return without duplicates.
4. Change the bank and tickets; start/end a wave; spawn/destroy a FOB and complete/expire the bonus objective. The board should reflect changes within the next phase tick, normally one second. Startup and long spawning operations can delay the server snapshot; local marker expiry continues independently.
5. Test extraction, no-player waiting and mission end. Check map-click artillery selection still works, and placing/moving buildings preserves ping/ready actions.
6. Check small/normal/large UI sizes and common aspect ratios. Labels must wrap without clipping or covering the central preparation timer. Close/recreate the HUD and respawn; the board must recover.

Static validation passed for delimiters/strings in 13 changed SQF/config files, three function registrations, translation references and five dynamic phase keys. XML parsing passed, and all 17 English/Polish entries preserve format placeholders. The SQF harness and multiplayer/UI checks have not been executed and require Arma. Static validation alone does not establish runtime correctness.
