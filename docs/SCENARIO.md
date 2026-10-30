# Scenario overview

Bulwark Fixed is an Arma 3 cooperative survival mission derived from Dynamic Bulwarks / SMITH Edition, with later Polish-versus-Russian content and a mobile Bulwark truck. It is mission source, not a standalone executable. The mission header supports 1–25 players.

## Gameplay loop

Players start near the Bulwark, scavenge gear and use kill points to buy defenses, allies and support. A shared bank and respawn tickets support team progression. Between combat waves players receive build time. Enemy numbers, equipment tiers and special attacks increase over the run.

The Bulwark can move. Spawn placement generally uses a current living conscious human as an anchor, falling back to the truck when none are available. Not every subsystem uses the same anchor: extraction is placed relative to the truck and some loot/defense functions remain truck-centered.

Each combat wave gets a bonus location. A living conscious player reaching it earns a shared bank bonus; it expires at wave end. After wave 4, an optional extraction area is revealed roughly five kilometres from the truck's position when it is created. Every living human survivor, including unconscious survivors, must be within 100 metres at the same time and at least one must be conscious. Dead players and headless clients are excluded. Extraction can succeed during combat.

Failure requires 45 continuous seconds with no able human survivor, no remaining tickets and no reserved paid respawn. A configured positive wave limit gives another success condition; -1 means unlimited. Extraction takes precedence over defeat or the wave limit.

## Team preparation and coordination

During intermission, **Ready to skip preparation** submits one vote for the current phase. A strict majority of connected, living, conscious WEST humans can shorten the wait after 15 seconds by default; the final 15-second warning remains. Dead spectators, incapacitated players, AI and headless clients do not vote. Joining/leaving and eligibility changes update the quorum. See [ready-vote settings and timing](READY_VOTE.md).

The HUD shows points, wave/phase, tickets, shared bank and public FOB/bonus objectives. Aim at a ground point and use **Ping: Threat**, **Supply**, **Repair** or **Regroup** to report it on teammates' maps. Range is 1 km, cooldown five seconds, lifetime 45 seconds, with one report per author and 16 team-wide. Reports are manual fixed positions and clear on author death/disconnect, expiry or extraction. Labels support English and Polish. See [tactical controls and limits](TACTICAL_STATUS.md).

## Enemies and specials

In Polish-versus-Russian mode, the catalogues select Russian enemy tiers and PSZ allies/vehicles. Legacy mode uses alternate lists. Defectors use RESISTANCE and are hostile to both WEST and EAST.

Specials include fog, night, suicide bombers, drones, mortars, artillery/Grad salvos, aircraft strikes, paradrops, truck transports and reinforcement FOBs. A FOB has a destructible ammunition cache; it keeps producing reinforcements and prevents wave completion until destroyed. Its surviving defenders then attack. The existing FOB is eligible from wave 7 onward with at most one active/setup instance. By default, two intervening waves separate successful deployments (wave 7 permits another from wave 10); selection remains probabilistic.

Fog, night and thunderstorm are unique per wave. [Thunderstorms](THUNDERSTORM.md) add dark clouds, heavy rain, ambient lightning and occasional nearby ground strikes; normal wave/mission completion restores the saved weather. Repeated combat effects remain possible. Automatic vehicles are separate from the special-wave selector, so Specials Off alone is not an infantry-only setting. See [wave mechanics](WAVES_AND_AI.md).

[Officer Hunt](OFFICER_HUNT.md), selectable from wave 10, places a command squad in an approximate search area. Killing its officer stops periodic infantry reinforcements and sends surviving guards into the attack. Two reinforcement teams/eight soldiers can remain alive at once. After ten minutes, the post abandons defense and assaults instead. This special cannot stack with an enemy FOB; it has its own two-intervening-wave cooldown.

## Economy, recovery and building

Purchases resolve catalogue IDs and prices on the server. Bank transfers, healing, spinning loot boxes and ticket purchases also validate server-side. Bought objects are created by the server and handed back to the player for placement. Allied infantry patrol; static/vehicle crews hold their placed position.

A death reserves a ticket for that corpse. Free build-phase respawns and paid combat delay are separate. Revival executes on the unit's owning machine. Inventory conversion trades ten first-aid kits for one Medikit while preserving leftovers and unrelated cargo.

## Feature configuration

| Setting in editMe.sqf | Default | Effect |
| --- | --- | --- |
| BW_READY_VOTE_ENABLED | true | Enable the intermission ready vote. |
| BW_READY_MIN_PREP | 15 | Seconds before a vote may shorten preparation; final warning follows. Never lengthens a shorter natural intermission. |
| BW_FOB_COOLDOWN_WAVES | 2 | Complete intervening waves before another successful FOB deployment. |

Ping range/cooldown/lifetime/cap are currently source constants in requestPing and tacticalClient, not lobby options. Support-charge availability and new FOB variants are not implemented.

## Configuration and content

- [description.ext](../description.ext): lobby options, function includes, revive/respawn settings, remote-execution policy and endings.
- [editMe.sqf](../editMe.sqf): translates lobby values into gameplay globals and defines shop/support configuration.
- [hostiles/lists.sqf](../hostiles/lists.sqf): faction/class catalogues.
- [locationLists.sqf](../locationLists.sqf) and [mission.sqm](../mission.sqm): placement choices and editor objects/markers.

Required content is determined by the actual catalogues and scripts. They reference PSZ, RHS, CUP and LAMBS; the historical README's dependency list is not exhaustive. Startup explicitly checks the PSZ Bulwark truck and that each infantry tier has at least one loaded class, not every optional asset. Current remote-control checks require Arma 3 2.14 or later.

Parameter migration: HOSTILE_MULTIPLIER uses integer values 50/100/200/300 divided by 100. Old server overrides using 0.5/1/2/3 must be updated. HOSTILE_TEAM_MULTIPLIER also uses a percentage converted in editMe.sqf. Read the current lobby definitions before copying server presets.
