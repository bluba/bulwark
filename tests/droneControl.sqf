/* Hosted idle editor session only, with a living player and no active remote control:
   [] execVM "tests\droneControl.sqf";
   Exercises the actual client control functions with temporary UAVs.
   Operator death/respawn and dedicated-server dispatch require separate MP checks. */
if (!hasInterface || {!isServer} || {!canSuspend} || {!alive player}) exitWith {};
if (missionNamespace getVariable ["runMissionLoop", false]) exitWith {diag_log "Drone tests require an idle mission loop"};
if (isRemoteControlling player || {cameraOn != player}) exitWith {diag_log "Drone tests require the player's normal camera"};
private _oldSession = missionNamespace getVariable ["BW_droneControlSession", []];
if !(_oldSession isEqualTo []) exitWith {diag_log "Drone tests require no active Predator session"};
private _terminal = (assignedItems player) select {_x isKindOf ["UavTerminal_base", configFile >> "CfgWeapons"]};
private _oldGPS = (assignedItems player) select {_x isKindOf ["ItemGPS", configFile >> "CfgWeapons"]};
BW_droneControlFailures = [];
private _check = {
    params ["_ok", "_message"];
    if (!_ok) then {BW_droneControlFailures pushBack _message; diag_log ("DRONE TEST FAILED: " + _message)};
};
private _assets = [];
private _newUav = {
    private _result = [player getPos [100, random 360], 0, "B_UAV_01_F", west] call BIS_fnc_spawnVehicle;
    _assets pushBack _result;
    {_x disableAI "PATH"} forEach (_result select 1);
    _result select 0
};
private _start = {
    params ["_uav"];
    [player, _uav] spawn supports_fnc_beginDroneControl;
    sleep 0.5;
    [isRemoteControlling player && {remoteControlled player in crew _uav}, "UAV control acquired"] call _check;
    (missionNamespace getVariable ["BW_droneControlSession", []]) param [0, -1]
};
private _restored = {
    [!isRemoteControlling player && {cameraOn isEqualTo player}, "Control and camera returned to player"] call _check;
    [(missionNamespace getVariable ["BW_droneControlSession", []]) isEqualTo [], "Session cleared"] call _check;
};

// Dead pilot, deleted pilot, and deletion of the complete UAV are separate engine cases.
{
    private _uav = call _newUav;
    [_uav] call _start;
    switch (_x) do {
        case "killPilot": {(driver _uav) setDamage 1};
        case "deletePilot": {deleteVehicle (driver _uav)};
        case "killUav": {_uav setDamage 1};
        case "deleteUav": {deleteVehicle _uav};
    };
    sleep 0.5;
    call _restored;
} forEach ["killPilot", "deletePilot", "killUav", "deleteUav"];

// A stale finalizer must not cancel a newer Predator session.
private _first = call _newUav;
private _firstId = [_first] call _start;
private _second = call _newUav;
private _secondId = [_second] call _start;
[_firstId] call supports_fnc_endDroneControl;
_first setDamage 1;
sleep 0.5;
[isRemoteControlling player && {remoteControlled player in crew _second}, "Old session cannot release new Predator"] call _check;

// An external takeover does not replace our token: check actual target and camera too.
private _third = call _newUav;
player remoteControl objNull;
(driver _third) switchCamera "INTERNAL";
player remoteControl (driver _third);
sleep 0.5;
[_secondId] call supports_fnc_endDroneControl;
_second setDamage 1;
sleep 0.5;
[isRemoteControlling player && {remoteControlled player in crew _third} && {cameraOn isEqualTo driver _third}, "External control and camera preserved"] call _check;

player remoteControl objNull;
player switchCamera "INTERNAL";
private _session = missionNamespace getVariable ["BW_droneControlSession", []];
if !(_session isEqualTo []) then {[_session select 0] call supports_fnc_endDroneControl};
{
    _x params ["_uav", "_crew", "_group"];
    {deleteVehicle _x} forEach _crew;
    deleteVehicle _uav;
    deleteGroup _group;
} forEach _assets;
if (_terminal isEqualTo []) then {player unlinkItem "B_UavTerminal"; player removeItem "B_UavTerminal"};
{player linkItem _x} forEach (_oldGPS + _terminal);
diag_log format ["DRONE CONTROL REGRESSION COMPLETE: %1 failures", count BW_droneControlFailures];
