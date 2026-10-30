// Called unscheduled by the server preparation loop: roster, quorum and commit
// are evaluated together. Only this loop may shorten the deadline.
if (!isServer || {isRemoteExecuted}) exitWith {};
private _eligible = ([] call bulwark_fnc_readyVoters) apply {getPlayerUID _x};
BW_READY_VOTERS = BW_READY_VOTERS arrayIntersect _eligible;
private _required = floor ((count _eligible) / 2) + 1;
if (BW_READY_OPEN && {buildPhase} && {!missionExtract} && {runMissionLoop} &&
    {time >= BW_READY_MIN_DEADLINE} && {count BW_READY_VOTERS >= _required}) then {
    BW_PREP_DEADLINE = BW_PREP_DEADLINE min (time + 15);
    BW_READY_OPEN = false;
};
if (missionExtract || {!runMissionLoop} || {!buildPhase} ||
    {time >= BW_PREP_DEADLINE - 15}) then {BW_READY_OPEN = false};
private _state = [BW_READY_PHASE, BW_READY_OPEN, +BW_READY_VOTERS, count _eligible, _required];
if !(_state isEqualTo (missionNamespace getVariable ["BW_READY_STATE", []])) then {
    missionNamespace setVariable ["BW_READY_STATE", _state, true];
};
