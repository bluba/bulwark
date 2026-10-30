# F01: Ready-to-skip vote

Implemented the skip-only backlog slice. During intermission, use the player action **Ready to skip preparation**. The preparation timer and action show ready/eligible counts and the number required. A ready vote is final for that preparation phase.

The server requires a strict majority: one of one, two of two, two of three, three of four. Eligible players are connected, living, conscious WEST humans with a UID. Dead spectators, incapacitated players, AI, headless clients and other sides are excluded. Eligibility is recalculated each second; votes from players who leave eligibility are discarded, so returning players must vote again. JIP players immediately join the denominator and receive current vote state.

`editMe.sqf` settings:

- `BW_READY_VOTE_ENABLED = true`: enable the action and majority skip.
- `BW_READY_MIN_PREP = 15`: earliest time after intermission opens that a vote can pass. Votes can be submitted earlier. The final 15-second warning follows, giving about 30 seconds total at defaults.

The minimum limits vote-driven shortening; it never lengthens a naturally shorter configured intermission. No votes, voting disabled or no eligible players leaves the normal `DOWN_TIME + min(240, wave * ADDITIONAL_DOWN_TIME) + 15` duration intact. The first wave retains its startup warning and has no ready vote. Preparation and the final warning share one server deadline; passing the vote only shortens that deadline. If an empty server waits beyond the deadline, returning players receive a fresh 15-second warning.

The remote request checks player ownership, eligibility, build phase, mission state and the phase ID captured when the action was created. Duplicate votes count once. Voting closes before the final countdown and on extraction. Requests never start a wave; the existing mission loop remains the sole wave-start owner. The client only removes its own action, recreates it after respawn or removal, and receives public state when joining.

## Validation

`tests/readyVote.sqf` exercises the actual server functions in an idle Arma session with at least one living WEST human. It checks stale/invalid/duplicate requests, minimum delay, strict majority, departed votes, single deadline commit, closed voting, extraction and combat rejection. Stop the normal mission loop before running it; it restores the globals it modifies. Run with one player and again with multiple players. This harness does not test network ownership or render the UI.

In a hosted and a dedicated multiplayer session, verify:

1. One of three players votes: countdown continues. A second votes before 15 seconds: skip waits until 15 seconds, then the final warning counts down once and exactly one wave starts.
2. Join or disconnect during voting: denominator and required majority update within a tick. Incapacitation/death removes eligibility and its vote; respawning restores an unvoted eligible player.
3. Submit a request using another client's player object: server rejects it. Resend the previous phase ID in the next preparation: rejected.
4. Join during preparation, respawn, and place/move a building: exactly one ready action appears when eligible; unrelated actions remain. After voting, it disappears when the server publishes acknowledgement.
5. No votes, disabled voting, zero downtime, and minimum greater than downtime: natural timer remains unchanged; no extra countdown is appended. Empty roster cannot pass a vote.
6. Extraction during preparation or warning cancels progression. First-wave startup still works; later waves get fresh vote phases. Leaving the server empty beyond the deadline gives returning players a warning.

Static source checks are available outside Arma; execution, UI and multiplayer acceptance require an in-game run.
