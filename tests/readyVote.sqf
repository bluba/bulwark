/* Server/editor regression checks. Run only with the normal mission loop stopped,
   and at least one living, conscious WEST human connected:
   [] execVM "tests\readyVote.sqf";
   Results go to RPT. Does not start waves or change player health/position.
   See docs/READY_VOTE.md for multiplayer and UI checks.
*/
if (!isServer || {isRemoteExecuted}) exitWith {};
if (missionNamespace getVariable ["runMissionLoop", false]) exitWith {
    diag_log "READY test requires the normal mission loop to be stopped";
};
private _players = [] call bulwark_fnc_readyVoters;
if (_players isEqualTo []) exitWith {diag_log "READY test requires a living WEST human"};
// Run atomically so clients cannot submit votes during synthetic phases.
isNil {
    private _names = ["BW_READY_PHASE", "BW_READY_OPEN", "BW_READY_VOTERS", "BW_PREP_DEADLINE",
        "BW_READY_MIN_DEADLINE", "BW_READY_STATE", "buildPhase", "missionExtract", "runMissionLoop"];
    private _saved = _names apply {[!isNil _x, missionNamespace getVariable [_x, false]]};
    private _failures = [];
    private _check = {
        params ["_ok", "_label"];
        if (!_ok) then {_failures pushBack _label; diag_log ("READY FAIL: " + _label)};
    };
    BW_READY_PHASE = 987654;
    BW_READY_OPEN = true;
    BW_READY_VOTERS = [];
    BW_PREP_DEADLINE = time + 120;
    BW_READY_MIN_DEADLINE = time + 30;
    buildPhase = true; missionExtract = false; runMissionLoop = true;
    private _player = _players select 0;
    [_player, BW_READY_PHASE - 1] call bulwark_fnc_requestReady;
    [BW_READY_VOTERS isEqualTo [], "stale phase rejected"] call _check;
    [objNull, BW_READY_PHASE] call bulwark_fnc_requestReady;
    [BW_READY_VOTERS isEqualTo [], "invalid player rejected"] call _check;
    [_player, BW_READY_PHASE] call bulwark_fnc_requestReady;
    [_player, BW_READY_PHASE] call bulwark_fnc_requestReady;
    [count BW_READY_VOTERS == 1, "duplicate vote counts once"] call _check;
    {[_x, BW_READY_PHASE] call bulwark_fnc_requestReady} forEach _players;
    private _deadline = BW_PREP_DEADLINE;
    [] call bulwark_fnc_updateReadyVote;
    [BW_READY_OPEN && {BW_PREP_DEADLINE == _deadline}, "majority waits for minimum preparation"] call _check;
    BW_READY_MIN_DEADLINE = time - 1;
    BW_READY_VOTERS = (_players select [0, floor ((count _players) / 2)]) apply {getPlayerUID _x};
    [] call bulwark_fnc_updateReadyVote;
    [BW_READY_OPEN && {BW_PREP_DEADLINE == _deadline}, "half or fewer cannot skip"] call _check;
    BW_READY_VOTERS = (_players apply {getPlayerUID _x}) + ["disconnected-test-uid"];
    [] call bulwark_fnc_updateReadyVote;
    [!("disconnected-test-uid" in BW_READY_VOTERS), "departed votes removed"] call _check;
    [!BW_READY_OPEN && {abs (BW_PREP_DEADLINE - time - 15) < 0.1}, "majority commits final warning"] call _check;
    _deadline = BW_PREP_DEADLINE;
    [] call bulwark_fnc_updateReadyVote;
    [BW_PREP_DEADLINE == _deadline, "commit does not restart countdown"] call _check;
    BW_READY_VOTERS = [];
    [_player, BW_READY_PHASE] call bulwark_fnc_requestReady;
    [BW_READY_VOTERS isEqualTo [], "closed phase rejects votes"] call _check;
    BW_READY_OPEN = true; BW_PREP_DEADLINE = time + 120; missionExtract = true;
    [_player, BW_READY_PHASE] call bulwark_fnc_requestReady;
    [] call bulwark_fnc_updateReadyVote;
    [!BW_READY_OPEN && {BW_READY_VOTERS isEqualTo []}, "extraction cancels voting"] call _check;
    missionExtract = false; buildPhase = false; BW_READY_OPEN = true;
    [_player, BW_READY_PHASE] call bulwark_fnc_requestReady;
    [] call bulwark_fnc_updateReadyVote;
    [!BW_READY_OPEN && {BW_READY_VOTERS isEqualTo []}, "combat rejects votes"] call _check;
    {
        private _savedValue = _saved select _forEachIndex;
        if (_savedValue select 0) then {
            missionNamespace setVariable [_x, _savedValue select 1, _x == "BW_READY_STATE"];
        } else {missionNamespace setVariable [_x, nil, _x == "BW_READY_STATE"]};
    } forEach _names;
    diag_log format ["READY tests complete: %1 failures %2", count _failures, _failures];
};
