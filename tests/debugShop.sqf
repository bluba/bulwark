/* Disposable idle server/editor only: [] execVM "tests\debugShop.sqf";
   Requires no hostile units and a living conscious host/dedicated admin within
   10 metres of the Bulwark. Creates temporary EAST/RESISTANCE/WEST test units.
   Calls the real server handler; restores its cooldown state and removes actors.
   Run normal-client/spoofed-owner rejection separately with two clients. */
if (!isServer || {!canSuspend}) exitWith {};
if (missionNamespace getVariable ["runMissionLoop", false] ||
    {(allUnits findIf {alive _x && {side group _x in [east, resistance]}}) >= 0}) exitWith {
    diag_log "Debug shop test requires an idle mission with no hostile units";
};
private _callers = ([] call bulwark_fnc_humanPlayers) select {
    [_x, true] call bulwark_fnc_validCaller &&
    {(!isDedicated && {owner _x == 2}) || {admin (owner _x) > 0}}
};
if (_callers isEqualTo []) exitWith {diag_log "Debug shop test needs a living host/admin near the Bulwark"};
private _testCaller = _callers select 0;
private _hadCooldowns = !isNil "BW_DEBUG_NEXT";
private _savedCooldowns = missionNamespace getVariable ["BW_DEBUG_NEXT", createHashMap];
BW_DEBUG_NEXT = createHashMap;
private _failures = [];
private _check = {params ["_ok", "_label"]; if (!_ok) then {_failures pushBack _label; diag_log ("DEBUG SHOP FAIL: " + _label)}};
private _pos = (getPosATL bulwarkBox) vectorAdd [15, 15, 0];
private _groups = [createGroup [east, true], createGroup [resistance, true], createGroup [west, true]];
private _east = (_groups select 0) createUnit ["O_Soldier_F", _pos, [], 0, "NONE"];
private _resistance = (_groups select 1) createUnit ["I_Soldier_F", _pos, [], 0, "NONE"];
private _friendly = (_groups select 2) createUnit ["B_Soldier_F", _pos, [], 0, "NONE"];
{_x disableAI "ALL"} forEach [_east, _resistance, _friendly];
[_testCaller, "unknownAction"] call bulwark_fnc_requestDebugAction;
[alive _east && {alive _resistance}, "unknown action does nothing"] call _check;
[_testCaller, "killEnemies"] call bulwark_fnc_requestDebugAction;
[!alive _east && {!alive _resistance}, "host/admin kills both hostile sides"] call _check;
[alive _friendly && {alive _testCaller}, "friendly AI and caller survive"] call _check;
private _repeatGroup = createGroup [east, true];
_groups pushBack _repeatGroup;
private _repeat = _repeatGroup createUnit ["O_Soldier_F", _pos, [], 0, "NONE"];
_repeat disableAI "ALL";
[_testCaller, "killEnemies"] call bulwark_fnc_requestDebugAction;
[alive _repeat, "immediate duplicate is rate limited"] call _check;
sleep 2.1;
[_testCaller, "killEnemies"] call bulwark_fnc_requestDebugAction;
[!alive _repeat && {alive _friendly}, "action works again after cooldown"] call _check;
{deleteVehicle _x} forEach [_east, _resistance, _friendly, _repeat];
{deleteGroup _x} forEach _groups;
if (_hadCooldowns) then {BW_DEBUG_NEXT = _savedCooldowns} else {BW_DEBUG_NEXT = nil};
// Validate force requests without starting a second mission-loop owner.
private _debugNames = ["runMissionLoop", "missionExtract", "missionFailure", "BW_DEBUG_NEXT_SPECIAL", "BW_DEBUG_TRANSITION", "BW_DEBUG_NEXT"];
private _debugSaved = _debugNames apply {[!isNil _x, missionNamespace getVariable [_x, false]]};
runMissionLoop = true; missionExtract = false; missionFailure = false;
BW_DEBUG_NEXT_SPECIAL = ""; BW_DEBUG_TRANSITION = false; BW_DEBUG_NEXT = createHashMap;
[_testCaller, "forceSpecial", "notASpecial"] call bulwark_fnc_requestDebugAction;
[BW_DEBUG_NEXT_SPECIAL == "" && {!BW_DEBUG_TRANSITION}, "unknown special cannot queue a transition"] call _check;
[_testCaller, "forceSpecial", "thunderstorm"] call bulwark_fnc_requestDebugAction;
[BW_DEBUG_NEXT_SPECIAL == "thunderstorm" && {BW_DEBUG_TRANSITION}, "valid special queues exactly one transition"] call _check;
[_testCaller, "forceSpecial", "nightWave"] call bulwark_fnc_requestDebugAction;
[BW_DEBUG_NEXT_SPECIAL == "thunderstorm", "busy transition cannot be overwritten"] call _check;
{private _value = _debugSaved select _forEachIndex; if (_value select 0) then {missionNamespace setVariable [_x, _value select 1]} else {missionNamespace setVariable [_x, nil]}} forEach _debugNames;
diag_log format ["Debug shop tests complete: %1", _failures];
