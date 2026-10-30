/* Idle hosted editor with mission functions and LAMBS loaded:
   [] execVM "tests\friendlyBulwark.sqf";
   Calls the actual friendly controller with temporary assets. No mocks.
   Driving/navigation, HC transfer, aircraft and support insertion require MP tests. */
if (!isServer || {!hasInterface} || {!canSuspend} || {!alive player}) exitWith {};
if (missionNamespace getVariable ["runMissionLoop", false]) exitWith {diag_log "Friendly tests require an idle mission loop"};
if (isNil "lambs_wp_fnc_taskPatrol") exitWith {diag_log "Friendly tests require LAMBS"};
private _savedTruck = missionNamespace getVariable ["bulwarkBox", objNull];
private _hadLoop = !isNil "runMissionLoop";
private _savedLoop = missionNamespace getVariable ["runMissionLoop", false];
BW_friendlyFailures = [];
private _check = {
    params ["_ok", "_message"];
    if (!_ok) then {BW_friendlyFailures pushBack _message; diag_log ("FRIENDLY TEST FAILED: " + _message)};
};
private _position = player getPos [300, 0];
private _truck = createVehicle ["B_Truck_01_transport_F", _position, [], 0, "NONE"];
_truck allowDamage false;
bulwarkBox = _truck;
runMissionLoop = true;
private _group = createGroup [west, true];
private _unit = _group createUnit ["B_Soldier_F", _truck getPos [5, 0], [], 0, "NONE"];
removeAllWeapons _unit;
_unit allowDamage false;
_group setVariable ["bw_allyDuty", "patrol", true];
[_group, _unit] call bulwark_fnc_followBulwark;
private _job = _group getVariable ["bw_allyServerJob", scriptNull];
[_group, _unit] call bulwark_fnc_followBulwark;
[(_group getVariable ["bw_allyServerJob", scriptNull]) isEqualTo _job, "Registration keeps one server controller"] call _check;
[_group, _unit, _truck] call bulwark_fnc_controlAllyGroup;
[(_group getVariable ["bw_allyMode", ""]) == "patrol", "Infantry patrols near stopped truck"] call _check;
[((waypoints _group) findIf {(waypointPosition _x) distance2D _truck > 65}) < 0, "Patrol targets remain inside inner radius/tolerance"] call _check;

// A relocated truck invalidates the old placement position.
_truck setPosATL (_position vectorAdd [150, 0, 0]);
[_group, _unit, _truck] call bulwark_fnc_controlAllyGroup;
[(_group getVariable ["bw_allyMode", ""]) == "follow", "Truck relocation recalls allies"] call _check;
[(_group getVariable ["bw_allyMoveTarget", [0, 0, 0]]) distance2D _truck <= 25, "Follow target tracks new truck position"] call _check;

// Simulate arrival after the settle deadline; no pathfinding timing assumption.
_unit setPosATL (_truck getPos [5, 0]);
_group setVariable ["bw_allyMovingUntil", 0];
_group setVariable ["bw_allyTruckPos", getPosATL _truck];
[_group, _unit, _truck] call bulwark_fnc_controlAllyGroup;
[(_group getVariable ["bw_allyMode", ""]) == "patrol", "Arrival resumes duty around new center"] call _check;
_group setVariable ["bw_allyDuty", "camp", true];
[_group, _unit, _truck] call bulwark_fnc_controlAllyGroup;
[(_group getVariable ["bw_allyMode", ""]) == "camp", "Camp guard duty selected"] call _check;
[((waypoints _group) findIf {waypointType _x == "HOLD" && {(waypointPosition _x) distance2D _truck <= 25}}) >= 0, "Camp uses nearby cancellable guard waypoint"] call _check;

_unit setVariable ["buildItemHeld", true, true];
[_group, _unit, _truck] call bulwark_fnc_controlAllyGroup;
[(_group getVariable ["bw_allyMode", ""]) == "held", "Carried ally pauses duty"] call _check;
_unit setVariable ["buildItemHeld", false, true];
[_group, _unit, _truck] call bulwark_fnc_controlAllyGroup;
[(_group getVariable ["bw_allyMode", ""]) == "camp", "Placed ally resumes duty"] call _check;

private _before = waypoints _group apply {waypointPosition _x};
_unit setVariable ["BIS_fnc_moduleRemoteControl_owner", player];
_truck setPosATL (_position vectorAdd [300, 0, 0]);
[_group, _unit, _truck] call bulwark_fnc_controlAllyGroup;
[(waypoints _group apply {waypointPosition _x}) isEqualTo _before, "Zeus control prevents new movement orders"] call _check;
_unit setVariable ["BIS_fnc_moduleRemoteControl_owner", nil];

private _static = [getPosATL _truck, 0, "B_HMG_01_high_F", west] call BIS_fnc_spawnVehicle;
_static params ["_gun", "_crew", "_gunGroup"];
[_gunGroup, _gun] call bulwark_fnc_followBulwark;
[_gunGroup, _gun, _truck] call bulwark_fnc_controlAllyGroup;
_truck setPosATL (_position vectorAdd [450, 0, 0]);
[_gunGroup, _gun, _truck] call bulwark_fnc_controlAllyGroup;
[(_gunGroup getVariable ["bw_allyMode", ""]) == "static", "Static weapon does not receive impossible follow order"] call _check;

{
    _x setVariable ["bw_allyManaged", false, true];
    private _handle = _x getVariable ["bw_allyServerJob", scriptNull];
    if (!scriptDone _handle) then {terminate _handle};
} forEach [_group, _gunGroup];
sleep 1.5;
{deleteVehicle _x} forEach _crew;
deleteVehicle _gun;
deleteGroup _gunGroup;
deleteVehicle _unit;
deleteGroup _group;
deleteVehicle _truck;
bulwarkBox = _savedTruck;
if (_hadLoop) then {runMissionLoop = _savedLoop} else {missionNamespace setVariable ["runMissionLoop", nil]};
diag_log format ["FRIENDLY BULWARK REGRESSION COMPLETE: %1 failures", count BW_friendlyFailures];
