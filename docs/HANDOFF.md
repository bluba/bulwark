# Handoff and current status

## Source of truth

Work in [dynamicBulwarks.Altis](../), the current workspace root and parent of this docs directory. The source was previously named Altis.bulwarkFixed; older reports use that name. There is no separate active mission subdirectory in this workspace.

The active baseline was extracted from Workshop item 2995798737:

- Original archive: F:/SteamLibrary/steamapps/workshop/content/107410/2995798737/50200269972067804_legacy.bin.
- It contained an uncompressed PBO; 190 original entries were extracted and byte-verified.
- Source archive SHA-256: 4FFA3B9E0EE868B7BCF5BD7D87B4702DAC3E0FF766D13C0D3D6D4211931ABFEC.
- The earlier extraction record referenced recovered-workshop-2995798737.extraction.json. That manifest and original archive are not present in this workspace; the paths and hash here record provenance, not locally verified artifacts.
- Recovered source was initially named recovered-workshop-2995798737, then moved to Altis.bulwarkFixed at the user's request.
- No Git repository was present during this work. The manifest provides original file hashes, not version history for intermediate fixes.

## User decisions to preserve

- Use the recovered Workshop version as the baseline.
- Keep gameplay code in the current dynamicBulwarks.Altis mission root; retain the earlier Altis.bulwarkFixed name only when describing provenance.
- **Do not create a PBO unless the user changes this instruction.** Earlier notes mention an obsolete Bulwark_fixed.Altis.pbo; no current build is provided in this workspace.
- Ordinary infantry budget is linear. Active limit is min(120, 30 + 4 × human players); ordinary infantry uses up to 80% of that capacity.
- Combat specials may repeat. Fog and night may each occur only once in a wave.
- All Markdown documentation belongs in this docs directory.

## Work already implemented

The Debug shop now lists all 16 implemented specials and can end/drain the current wave before starting the selected special at the next wave number. The mission loop remains the only start owner. One-wave overrides bypass selection gates; shared capacity/content validation remain. Static checks passed; transition/UI/dedicated acceptance and both debug harnesses are unrun. See [DEBUG_SHOP.md](DEBUG_SHOP.md).

[Shop Debug tab](DEBUG_SHOP.md), added 2026-10-30, exposes a host/admin-only **Kill all enemies** action in Shop +. The server validates caller/proximity/admin status, accepts a fixed action ID and rate-limits duplicate requests. It kills current enemy AI without cancelling reinforcement producers or destroying FOB caches. Static checks passed; the new debug harness and actual UI/dedicated/HC acceptance remain unrun.

The patch set covers extraction/bonus objectives, FOB completion, ticket reservation and revival, server-side shop/bank transactions, aircraft cancellation, finite loot placement, lobby parameter corrections, special-wave lifecycle, streaming reinforcements and enemy AI control. Read [FIXES.md](FIXES.md) for details rather than reapplying historical review findings.

Latest AI changes introduce owner-local task dispatch, tracked LAMBS script handles, group-preserving resets, dedicated bomber movement, 10/25 metre CQB thresholds, protected transport insertion, singleton defense-object watching and conservative on-foot anti-stuck cleanup. Ordinary infantry no longer receives permanent behavior overrides from each placed defense.

Special-wave follow-up fixes now restore surviving mortar crew to assault control, discard spawns cancelled during engine creation and require an in-range paradrop pass after capacity waiting. `tests/spawnCapacity.sqf` adds creation-race cases; only static checks have run. Mortar projectile cleanup remains open. See [SPECIAL_WAVES_REVIEW.md](SPECIAL_WAVES_REVIEW.md).

[Thunderstorm](THUNDERSTORM.md) is now a unique weather special from wave 5, with full clouds, heavy rain, ambient lightning and occasional nearby native strikes. Singleton worker, saved-weather restoration, explicit intermission/mission-end cleanup and current-state client/JIP lightning are implemented. Its new engine harness remains unrun; dedicated visuals/native damage locality and JIP require acceptance.

[Officer Hunt](OFFICER_HUNT.md) is implemented from wave 10: officer/four guards, approximate search area/HUD, four-man reinforcement teams every 90 seconds with two-team/eight-soldier cap, two intervening waves of cooldown, FOB exclusivity and a ten-minute assault fallback. Owner-local defense/handoff/deletion, independent recovery and bounded shared-gateway requests are included. Its harness and extended capacity deadline cases remain unrun; gameplay/HC/Zeus/JIP acceptance is pending.

### Implemented feature slices (2026-10-29)

- **F01:** ready-to-skip vote, strict majority of living conscious WEST humans, live quorum, captured phase ID, default 15-second minimum preparation plus final 15-second warning. [Settings and acceptance](READY_VOTE.md).
- **F09:** existing reinforcement-cache FOB eligible from wave 7 onward, at most one active/setup instance and a configurable cooldown. Default deployment in wave 7 allows another from wave 10. New variants remain deferred. [Implementation record](FIXES.md#f09-recurring-fobs).
- **F12:** shared wave/phase/ticket/bank/objective board and four manually placed ping types. Pings have a five-second UID cooldown, 45-second lifetime and 16-report team cap. English/Polish labels; support-charge inventory remains deferred. [Controls and acceptance](TACTICAL_STATUS.md).
- **F15:** independent 20% medical-cache roll each combat wave, including wave one; one attempt per wave and one instance. Six FAKs and one Medikit subject to loot restrictions, bounded placement and 180-second expiry. Survives preparation; cancels on next combat/relocation/extraction. F12 map/HUD countdown and JIP support. [Settings and acceptance](SUPPLY_CACHES.md).
- **F15 shop revision (2026-10-31):** Supplies tab now sells placeable medical (3,000 points) and engineering (3,000) crates through a validated server transaction. No automatic rolls/paradrops, temporary expiry or wave/relocation cleanup. Stock/cargo rules preserved. `tests/supplyShop.sqf` supersedes the retired automatic-cache/drop harnesses; engine acceptance pending. Earlier F15 delivery bullets below describe superseded behavior.
- **F15 delivery revision (2026-10-30):** both families now use VTOL/parachute/blue-smoke delivery matching the active Supply Drop support. Outdoor-only LZs, bounded transit/descent, post-landing stock/lifetime, in-flight state and registered asset cleanup. Contents/chances preserved; live flight/landing acceptance pending. `tests/supplyDelivery.sqf` adds controlled delivery/cleanup coverage.
- **F15 engineering extension:** implemented with its own 20% roll, random 1–2 AP/1–2 AT mines, 1–3 frag grenades, two smoke grenades and one of each permitted tool. Shared family-aware lifecycle, maximum two caches, 20-metre separation, typed cargo and independent UI/cleanup. Medical quantities/chance preserved. Native tools, mine behavior and both-family multiplayer acceptance remain untested.
- Additional source work includes friendly reinforcement follow controllers and drone control lifecycle fixes; see the latest sections of [FIXES.md](FIXES.md) and the corresponding test harnesses.

## Verification status

Static lexical, parameter, function-registration and targeted integration checks passed after source changes. These checks are not an SQF compiler or Arma simulation. Fifteen engine regression scripts are present in tests/; their preconditions and coverage are indexed in [DEVELOPMENT.md](DEVELOPMENT.md). They have not been executed during the documented source work. No multiplayer gameplay validation, late-wave performance measurement or server RPT review was completed.

The local log search found no running Arma process and no RPT in the default local application-data directory or workspace. The user redirected work to source review before wider log discovery. Do not treat that as proof that no server logs exist elsewhere.

## Next work and known boundaries

1. Run the regression scripts in their required environments, then dedicated-server tests with two clients and optional headless client. Inspect the matching RPT.
2. Measure server FPS, active hostile count, pending spawns and wave-clear time on later waves. The 120 cap is a chosen starting setting, not a benchmarked performance guarantee.
3. Validate the implemented F09 later-wave selection, cooldown, singleton setup and cache-destruction cancellation. Validate F01 quorum/countdown behavior and F12 JIP, expiry, action recovery and UI scales before accepting the first feature package.
4. Validate mod classes, aircraft loadouts, antimine UAV firing and installed LAMBS compatibility.
5. Broad CfgRemoteExec mode 2 is retained. Transaction checks do not constitute complete malicious-client hardening.
6. Headless-client movement dispatch is implemented but not tested. Server anti-stuck cleanup deliberately skips nonlocal infantry. Headless-client scoring is not comprehensively verified.
7. External Zeus/mod spawns count toward capacity but are not prevented by the mission gateway; a Zeus spawn can temporarily exceed the configured limit.
8. Dormant legacy scripts remain in the tree. Search callers before modifying or enabling them.

Use current file contents rather than old review line numbers. Update these docs when behavior, state ownership or test results change.

## FPV Operator source implementation (2026-10-30)

Station lifecycle, bounded crewless drone director, target fairness/cover checks, optional-addon wave selection, Debug entry and PL/EN HUD/search area are implemented. See [FPV_OPERATOR.md](FPV_OPERATOR.md) and [addon integration](FPV_MOD_INTEGRATION.md). Fixed settlement candidates supplement explicit sites/markers; they are not editor-verified navigation points. Static checks passed; the adapter/lifecycle harnesses and in-game multiplayer/flight/detonation acceptance remain unrun.

FPV validation update (2026-10-30): user RPT confirms station activation, physical flight, visibility loss, random search, reacquisition, Attack and native detonation success callback. Visual blast/damage, final deletion, dedicated multiplayer and automated harnesses remain unverified. See [FPV_OPERATOR.md](FPV_OPERATOR.md#review-and-observed-engine-results--2026-10-30) for evidence and review fixes; this supersedes earlier statements that no engine evidence exists.

Latest FPV review: fixed close-range reaction-delay bypass and Zeus body-distance audio culling. Terminal commitment and the attack buzz still need engine acceptance; the previously logged successful detonation predates them. See [FPV_OPERATOR.md](FPV_OPERATOR.md) for current behavior and targeted retests.
