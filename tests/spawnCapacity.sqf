/* Run on an idle server/editor with mission functions loaded, no running mission loop and no hostile units:
   [] execVM "tests\spawnCapacity.sqf";
   Tests actual spawn gateway, including guard/wave loss during group creation.
   Temporarily wraps BIS_fnc_spawnGroup to inject cancellation after real creation.
   Restores the function/globals and deletes its units. */
if (!isServer || {!canSuspend}) exitWith {};
if (missionNamespace getVariable ["runMissionLoop", false] || {{alive _x && {side group _x in [east, resistance]}} count allUnits > 0}) exitWith {diag_log "Capacity test requires an idle, empty hostile battlefield"};
private _names = ["runMissionLoop", "missionExtract", "buildPhase", "attkWave", "BW_ENEMY_LIMIT", "BW_SPAWN_QUEUE", "BW_SPAWN_SERIAL"];
private _saved = _names apply {[!isNil _x, missionNamespace getVariable [_x, false]]};
runMissionLoop = true; missionExtract = false; buildPhase = false; attkWave = 100;
BW_ENEMY_LIMIT = 10; BW_SPAWN_QUEUE = []; BW_SPAWN_SERIAL = 0;
BW_capacityFailures = [];
private _check = {params ["_ok", "_label"]; if (!_ok) then {BW_capacityFailures pushBack _label; diag_log ("FAIL: " + _label)}};
private _classes = []; for "_i" from 1 to 8 do {_classes pushBack "O_Soldier_F"};
private _first = [[[1000,1000,0], east, _classes], "group", 100, true] call bulwark_fnc_spawnLimited;
{_x disableAI "ALL"} forEach units _first;
[count units _first == 8, "ordinary quota fills to 80 percent"] call _check;
BW_testOrdinary = grpNull;
private _job = [] spawn {BW_testOrdinary = [[[1000,1000,0], east, ["O_Soldier_F", "O_Soldier_F"]], "group", 100, true] call bulwark_fnc_spawnLimited};
sleep 1;
[!scriptDone _job, "ordinary request waits at quota"] call _check;
private _special = [[[1000,1000,0], east, ["O_Soldier_F", "O_Soldier_F"]], "group", 100] call bulwark_fnc_spawnLimited;
[count units _special == 2, "special can consume reserve"] call _check;
// Four vacancies bring total back to six, allowing the two-unit ordinary batch.
{deleteVehicle _x} forEach ((units _first) select [0,4]);
private _deadline = time + 7;
waitUntil {sleep 0.1; scriptDone _job || {time > _deadline}};
[scriptDone _job && {count units BW_testOrdinary == 2}, "casualties release capacity"] call _check;
if (!scriptDone _job) then {terminate _job};
private _cancel = [] spawn {private _g = [[[1000,1000,0], east, ["O_Soldier_F"]], "group", 100, true] call bulwark_fnc_spawnLimited; if (!isNull _g) then {BW_capacityFailures pushBack "cancelled request spawned"; {deleteVehicle _x} forEach units _g; deleteGroup _g}};
sleep 1;
missionExtract = true;
_deadline = time + 7;
waitUntil {sleep 0.1; scriptDone _cancel || {time > _deadline}};
[scriptDone _cancel, "extraction cancels waiting request"] call _check;
if (!scriptDone _cancel) then {terminate _cancel};
[BW_SPAWN_QUEUE isEqualTo [], "reservations released"] call _check;
{{deleteVehicle _x} forEach units _x; deleteGroup _x} forEach [_first, _special, BW_testOrdinary];
// Empty battlefield: first prove a valid guarded result is still admitted.
missionExtract = false;
private _raceGuard = createVehicle ["Box_East_Ammo_F", [1000,1000,0], [], 0, "NONE"];
private _validGuarded = [[[1000,1000,0], east, ["O_Soldier_F"]], "group", 100, false, _raceGuard] call bulwark_fnc_spawnLimited;
[count units _validGuarded == 1 && {_validGuarded getVariable ["bw_scriptedMovement", false]}, "valid guarded group remains protected"] call _check;
[(_raceGuard getVariable ["bw_capacityWaiting", -1]) == 0, "successful guard waiting count released"] call _check;
{deleteVehicle _x} forEach units _validGuarded;
deleteGroup _validGuarded;

// Inject guard deletion after BIS has created the squad but before it returns.
// This tests the postcondition rather than cancellation of an ungranted request.
private _savedSpawnGroup = BIS_fnc_spawnGroup;
private _raceUnits = [];
private _raceGroup = grpNull;
BIS_fnc_spawnGroup = {
    _raceGroup = _this call _savedSpawnGroup;
    _raceUnits = +(units _raceGroup);
    deleteVehicle _raceGuard;
    _raceGroup
};
private _guardCancelled = [[[1000,1000,0], east, ["O_Soldier_F", "O_Soldier_F"]], "group", 100, false, _raceGuard] call bulwark_fnc_spawnLimited;
BIS_fnc_spawnGroup = _savedSpawnGroup;
sleep 0.1;
[isNull _guardCancelled && {isNull _raceGroup} && {(_raceUnits findIf {!isNull _x}) < 0}, "guard loss during creation discards entire result"] call _check;
[BW_SPAWN_QUEUE isEqualTo [], "guard race releases reservation"] call _check;
{deleteVehicle _x} forEach _raceUnits;
deleteGroup _raceGroup;
deleteVehicle _raceGuard;

// Cancellation during creation also applies without a guard.
_raceUnits = [];
_raceGroup = grpNull;
BIS_fnc_spawnGroup = {
    _raceGroup = _this call _savedSpawnGroup;
    _raceUnits = +(units _raceGroup);
    missionExtract = true;
    _raceGroup
};
private _waveCancelled = [[[1000,1000,0], east, ["O_Soldier_F", "O_Soldier_F"]], "group", 100] call bulwark_fnc_spawnLimited;
BIS_fnc_spawnGroup = _savedSpawnGroup;
sleep 0.1;
[isNull _waveCancelled && {isNull _raceGroup} && {(_raceUnits findIf {!isNull _x}) < 0}, "wave loss during creation discards entire result"] call _check;
[BW_SPAWN_QUEUE isEqualTo [], "wave race releases reservation"] call _check;
{deleteVehicle _x} forEach _raceUnits;
deleteGroup _raceGroup;
// Officer Hunt uses a bounded request; legacy callers above retain -1 defaults.
missionExtract = false;
private _expired = [[[1000,1000,0], east, ["O_Soldier_F"]], "group", 100, false, objNull, 0] call bulwark_fnc_spawnLimited;
[isNull _expired && {BW_SPAWN_QUEUE isEqualTo []}, "expired deadline rejected before queuing"] call _check;
BW_ENEMY_LIMIT = 2;
private _deadlineBlocker = createGroup [east, true];
private _blockerUnit = _deadlineBlocker createUnit ["O_Soldier_F", [1000,1000,0], [], 0, "NONE"];
_blockerUnit disableAI "ALL";
private _timed = [[[1000,1000,0], east, ["O_Soldier_F", "O_Soldier_F"]], "group", 100, false, objNull, time + 1] call bulwark_fnc_spawnLimited;
[isNull _timed && {BW_SPAWN_QUEUE isEqualTo []}, "waiting deadline releases reservation"] call _check;
deleteVehicle _blockerUnit; deleteGroup _deadlineBlocker;
_raceUnits = []; _raceGroup = grpNull;
BIS_fnc_spawnGroup = {
    _raceGroup = _this call _savedSpawnGroup;
    _raceUnits = +(units _raceGroup);
    sleep 0.3;
    _raceGroup
};
private _creationTimed = [[[1000,1000,0], east, ["O_Soldier_F"]], "group", 100, false, objNull, time + 0.2] call bulwark_fnc_spawnLimited;
BIS_fnc_spawnGroup = _savedSpawnGroup;
sleep 0.1;
[isNull _creationTimed && {count _raceUnits == 1} && {(_raceUnits findIf {!isNull _x}) < 0} && {BW_SPAWN_QUEUE isEqualTo []}, "creation deadline discards result and reservation"] call _check;
{deleteVehicle _x} forEach _raceUnits; deleteGroup _raceGroup;
{private _value = _saved select _forEachIndex; if (_value select 0) then {missionNamespace setVariable [_x, _value select 1]} else {missionNamespace setVariable [_x, nil]}} forEach _names;
diag_log format ["Capacity tests complete: %1", BW_capacityFailures];
