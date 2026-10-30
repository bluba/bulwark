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
private _drone = objNull;
isNil {
    _drone = createVehicle ["O_UAFPV_OG7V_AP",_position,[],0,"CAN_COLLIDE"];
    _drone setVariable ["bw_fpvOwned",true,true];
    ["prepare",_drone] call bulwark_fnc_fpvAdapter;
};
if (isNull _drone) exitWith {diag_log "FPV probe: spawn failed"};
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
diag_log format ["FPV probe: local=%1 alive=%2 displacement=%3 cleanup=%4", _local, _alive, _distance, _cleaned && {isNull _drone}];
// Fallback cleanup in this disposable probe if unexpected ownership prevented adapter cleanup.
if (!_cleaned) then {deleteVehicle _drone};
