/* Disposable idle hosted/editor session, server console:
   [getPosATL player] execVM "tests\fpvAdapter.sqf";
   Requires Ukraine FPV Drone. Does not detonate a warhead.
   Measures a simple scripted velocity segment and direct cleanup. */
params ["_origin"];
if (!isServer || {!canSuspend} || {missionNamespace getVariable ["runMissionLoop", false]}) exitWith {
    diag_log "FPV probe requires an idle disposable server mission";
};
if !( ["available"] call bulwark_fnc_fpvAdapter) exitWith {diag_log "FPV probe: addon unavailable"};
private _position = _origin vectorAdd [0, 30, 20];
private _result = [_position, 0, "O_UAFPV_OG7V_AP", east] call BIS_fnc_spawnVehicle;
_result params ["_drone", "_crew", "_group"];
if (isNull _drone) exitWith {diag_log "FPV probe: spawn failed"};
_drone setVariable ["bw_fpvOwned", true, true];
_group setVariable ["bw_scriptedMovement", true, true];
_drone setVariable ["UA_FPV_PayloadSwapProtected", true, true];
{_x disableAI "ALL"} forEach _crew;
private _start = getPosASL _drone;
private _deadline = time + 3;
while {time < _deadline && {alive _drone} && {local _drone}} do {
    _drone setVelocity [0, 5, 0];
    sleep 0.1;
};
private _distance = _start distance getPosASL _drone;
private _local = local _drone;
private _alive = alive _drone;
private _cleaned = ["cleanup", _drone] call bulwark_fnc_fpvAdapter;
sleep 0.2;
diag_log format ["FPV probe: local=%1 alive=%2 displacement=%3 cleanup=%4 crewRemoved=%5", _local, _alive, _distance, _cleaned && {isNull _drone}, (_crew findIf {!isNull _x}) < 0];
// Fallback cleanup in this disposable probe if unexpected ownership prevented adapter cleanup.
if (!_cleaned) then {{deleteVehicle _x} forEach _crew; deleteVehicle _drone};
deleteGroup _group;
