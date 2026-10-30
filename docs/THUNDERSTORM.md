# Thunderstorm special wave

Thunderstorm is a weather modifier available in the beginner pool from wave 5, the full wave 7–9 pool and later standard-modifier draws. It is probabilistic, appears at most once per wave and can stack with fog, night and combat specials. Specials Off disables selection and direct startup. Vehicle Never does not exclude it.

The server sets full overcast, 85% rain and a lightning level of 0.7. A notification announces the storm. The first scripted ground-strike attempt is after 20–35 seconds; subsequent attempts are 35–65 seconds apart. Short waves can finish before any ground strike. Natural weather lightning is separate from these attempts.

Each attempt samples at most 12 points, 100–250 metres from a random living human. Candidates must be on land inside the map, at least 60 metres from every living human, 75 metres from the Bulwark and 25 metres from nearby houses, static weapons, ammunition boxes and land vehicles. If no candidate qualifies, that attempt skips. These are position checks at selection, not immunity for people/assets moving into a strike afterward. Native lightning can cause damage.

## Ownership and lifecycle

`startStorm` saves the pre-storm overcast/rain/lightning once and starts one persistent wave-bound worker. It never adds that worker to `BW_SPAWN_JOBS`, so the storm cannot block wave completion. Duplicate starts do not replace the saved weather or worker. `endStorm` is idempotent and rejects cleanup for an older wave; normal intermission, extraction, defeat and wave-limit completion restore the saved weather and stop the worker. Fog and time are left to their existing modifiers.

The server publishes `BW_STORM_STATE = [wave, active, lightningLevel]`. Its ordinary weather synchronization supplies clouds/rain; the existing one-second client tick applies the lightning value locally, including for join-in-progress clients. `mission.sqm` enables manual lightning override, as required by `setLightnings`.

For each scripted strike, the server creates a disposable, tagged, server-owned invisible helipad. It dispatches `stormStrike` to the server and viewers without a JIP entry. The wrapper rejects remote senders other than server owner 2, expired dispatches, null/untagged targets, preparation and stale waves. It calls the built-in `BIS_fnc_moduleLightning`: clients render the local effects, while the server-local target supplies the native damage authority. Headless clients skip effects. Real players, vehicles and objectives are never passed to the module, and targets are not made curator-editable. Targets expire after ten seconds or are removed immediately by storm cleanup. Late joiners receive current storm weather, not a replay of past strikes.

Primary sources: [setLightnings](https://community.bistudio.com/wiki/setLightnings), [setRain](https://community.bistudio.com/wiki/setRain), [forceWeatherChange](https://community.bistudio.com/wiki/forceWeatherChange), [native lightning module and locality](https://community.bistudio.com/wiki/BIS_fnc_moduleLightning). Forced cloud updates can cause a brief rendering hitch; dedicated multiplayer behavior requires acceptance testing.

## Validation and acceptance

`tests/thunderstorm.sqf` is an idle disposable server/editor harness. It changes real weather and temporarily replaces the native lightning function with a counting stub, so its explicit strikes do no damage. It calls the actual storm functions/worker to check Specials gating, singleton/saved-weather preservation, absence from completion jobs, stale/idempotent cleanup, strike guards, target/worker cleanup and extraction cancellation. It restores the native function, mission state and weather. Run once with Specials On and once with Specials Off. It has not been executed here.

Required hosted/dedicated checks with two clients: full storm visuals/rain/thunder; a single native damage event per strike; JIP during the storm and after cleanup; Specials Off and vehicles Never; storm stacked with fog/night; no duplicate storm draw; correct weather restoration on intermission, extraction and mission endings; no replayed strike on reconnect; strike placement near moving/separated players; and no growing target/worker count over several waves. Native effects already in progress may finish their brief animation during a phase transition; new dispatches are cancelled.

Source verification passed: strings/comments/delimiters in 12 SQF/config files, all 43 Bulwark function source files, 16 active script references, the three storm selection pools, duplicate exclusion, Specials Off dispatch order, persistent-worker separation, intermission/mission-end hooks, client tick hookup, manual lightning override and non-JIP strike dispatch. These checks do not compile or execute SQF. No Arma runtime test or PBO build was performed.
