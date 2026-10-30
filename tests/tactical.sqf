/* Run locally on an idle mission server, with the normal mission loop stopped:
   [] execVM "tests\tactical.sqf";
   Requires one living conscious WEST human on the map. Does not move or injure
   players. Network ownership, JIP and UI tests are in docs/TACTICAL_STATUS.md.
*/
if (!isServer || {isRemoteExecuted}) exitWith {};
if (missionNamespace getVariable ["runMissionLoop", false]) exitWith {
    diag_log "TACTICAL test requires the normal mission loop to be stopped";
};
private _players = [] call bulwark_fnc_readyVoters;
if (_players isEqualTo []) exitWith {diag_log "TACTICAL test requires a living WEST human"};
isNil {
    private _names = ["BW_TACTICAL_PINGS", "BW_PING_TIMES", "BW_TEAM_STATUS", "runMissionLoop", "missionExtract", "buildPhase"];
    private _saved = _names apply {[!isNil _x, missionNamespace getVariable [_x, false]]};
    private _failures = [];
    private _check = {
        params ["_ok", "_label"];
        if (!_ok) then {_failures pushBack _label; diag_log ("TACTICAL FAIL: " + _label)};
    };
    private _player = _players select 0;
    private _uid = getPlayerUID _player;
    private _pos = getPosATL _player;
    runMissionLoop = true; missionExtract = false; buildPhase = true;
    BW_TACTICAL_PINGS = []; BW_PING_TIMES = createHashMap;
    [objNull, 0, _pos] call bulwark_fnc_requestPing;
    [_player, 4, _pos] call bulwark_fnc_requestPing;
    [_player, 0, ["bad", 1, 0]] call bulwark_fnc_requestPing;
    [_player, 0, [1, 2]] call bulwark_fnc_requestPing;
    [_player, 0, [-1, 1, 0]] call bulwark_fnc_requestPing;
    [_player, 0, [worldSize + 1, 1, 0]] call bulwark_fnc_requestPing;
    [BW_TACTICAL_PINGS isEqualTo [], "reject invalid caller/type/position/bounds"] call _check;
    private _far = [if ((_pos select 0) > worldSize / 2) then {1} else {worldSize - 1}, _pos select 1, 0];
    [_player, 0, _far] call bulwark_fnc_requestPing;
    [BW_TACTICAL_PINGS isEqualTo [], "reject out-of-range report"] call _check;
    [_player, 0, _pos] call bulwark_fnc_requestPing;
    [count BW_TACTICAL_PINGS == 1, "accept valid report"] call _check;
    private _first = +BW_TACTICAL_PINGS;
    [_player, 1, _pos] call bulwark_fnc_requestPing;
    [BW_TACTICAL_PINGS isEqualTo _first, "server cooldown prevents flood"] call _check;
    BW_PING_TIMES set [_uid, serverTime - 6];
    [_player, 3, _pos] call bulwark_fnc_requestPing;
    [count BW_TACTICAL_PINGS == 1 && {(BW_TACTICAL_PINGS select 0 select 2) == 3}, "new report replaces author's previous report"] call _check;
    // Synthetic records exercise the cap without requiring 17 connected clients.
    BW_TACTICAL_PINGS = [];
    for "_i" from 1 to 16 do {
        BW_TACTICAL_PINGS pushBack [str _i, _player, 0, _pos, "Test", serverTime + 45];
    };
    BW_PING_TIMES set [_uid, serverTime - 6];
    [_player, 2, _pos] call bulwark_fnc_requestPing;
    [count BW_TACTICAL_PINGS == 16 && {(BW_TACTICAL_PINGS select 0 select 0) == "2"}, "team cap evicts oldest report"] call _check;
    BW_TACTICAL_PINGS = [[_uid, _player, 0, _pos, "Expired", serverTime - 1],
        ["removed", objNull, 0, _pos, "Removed", serverTime + 45]];
    [] call bulwark_fnc_tacticalState;
    [BW_TACTICAL_PINGS isEqualTo [], "expired and deleted-author reports removed"] call _check;
    [(BW_TEAM_STATUS select 1) == "Preparation", "preparation board phase"] call _check;
    buildPhase = false;
    [] call bulwark_fnc_tacticalState;
    [(BW_TEAM_STATUS select 1) == "Combat", "combat board phase"] call _check;
    BW_PING_TIMES set [_uid, serverTime - 6];
    [_player, 0, _pos] call bulwark_fnc_requestPing;
    missionExtract = true;
    [] call bulwark_fnc_tacticalState;
    [_player, 1, _pos] call bulwark_fnc_requestPing;
    [BW_TACTICAL_PINGS isEqualTo [] && {(BW_TEAM_STATUS select 1) == "Extraction"}, "extraction clears and rejects reports"] call _check;
    runMissionLoop = false;
    [] call bulwark_fnc_tacticalState;
    [(BW_TEAM_STATUS select 1) == "Ended", "ended board phase"] call _check;
    {
        private _value = _saved select _forEachIndex;
        private _public = _x in ["BW_TACTICAL_PINGS", "BW_TEAM_STATUS"];
        if (_value select 0) then {missionNamespace setVariable [_x, _value select 1, _public]}
        else {missionNamespace setVariable [_x, nil, _public]};
    } forEach _names;
    diag_log format ["TACTICAL tests complete: %1 failures %2", count _failures, _failures];
};
