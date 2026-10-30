if (!isServer) exitWith {};
params [["_wave", attkWave]];
if !([_wave] call bulwark_fnc_waveActive) exitWith {};
private _side = if (defectorWave) then {resistance} else {east};
private _classes = (if (defectorWave) then {DEFECTOR_INF} else {HOSTILE_LEVEL_3}) select {
    isClass (configFile >> "CfgVehicles" >> _x)
};
if (_classes isEqualTo []) exitWith {diag_log "Bulwark: no valid FOB infantry classes"};
// Scheduled producers can overlap before the cache exists. Reserve the singleton
// slot without suspension, including for callers outside the normal wave selector.
private _reserved = false;
isNil {
    if ([_wave] call bulwark_fnc_fobAvailable) then {
        BW_FOB_SETUP_PENDING = true;
        _reserved = true;
    };
};
if (!_reserved) exitWith {};
private _location = [([] call bulwark_fnc_spawnAnchor), BULWARK_RADIUS + 300, BULWARK_RADIUS + 450, 20, 0] call BIS_fnc_findSafePos;
// Register the cache before any scenery or capacity waits. Failed/cancelled setup
// releases its slot without consuming the cooldown.
private _cache = objNull;
isNil {
    if ([_wave] call bulwark_fnc_waveActive) then {
        _cache = createVehicle ["Box_East_AmmoVeh_F", _location, [], 0, "NONE"];
        if (!isNull _cache && {alive _cache}) then {
            BW_ACTIVE_FOBS pushBack _cache;
            BW_FOB_LAST_WAVE = _wave;
        };
    };
    BW_FOB_SETUP_PENDING = false;
};
if (isNull _cache || {!alive _cache}) exitWith {
    deleteVehicle _cache;
    diag_log format ["Bulwark: FOB setup cancelled or cache creation failed in wave %1", _wave];
};
private _objects = [];
_objects pushBack _cache;
{
    if !([_wave] call bulwark_fnc_waveActive) exitWith {};
    private _position = [_location, 0, 25, 5, 0] call BIS_fnc_findSafePos;
    _objects pushBack (createVehicle [_x, _position, [], 0, "NONE"]);
} forEach ["Land_BagBunker_Small_F", "Land_BagBunker_Small_F", "Land_BagBunker_Big_F", "CamoNet_OPFOR_open_F", "Land_MedicalTent_01_aaf_generic_inner_F"];
// The marked cache remains a required objective until destroyed.
clearItemCargoGlobal _cache;
clearWeaponCargoGlobal _cache;
clearMagazineCargoGlobal _cache;
private _marker = format ["BulwarkFOB_%1_%2", _wave, floor random 1000000];
createMarker [_marker, _location];
_marker setMarkerType "mil_destroy";
_marker setMarkerColor "ColorRed";
_marker setMarkerText "FOB ammunition cache";
[] call bulwark_fnc_tacticalState;
if (!isNil "mainZeus") then {mainZeus addCuratorEditableObjects [_objects, true]};
["TaskAssigned", ["Enemy FOB", "Destroy the marked ammunition cache to stop reinforcements."]] remoteExec ["BIS_fnc_showNotification", 0];
private _spawnTeam = {
    params ["_location", "_side", "_classes", "_defend"];
    // A deleted cache is objNull; never pass it as an unguarded spawn request.
    if (!alive _cache || {!([_wave] call bulwark_fnc_waveActive)}) exitWith {grpNull};
    private _team = [];
    for "_i" from 1 to 10 do {_team pushBack (selectRandom _classes)};
    private _group = [[_location, _side, _team], "group", _wave, false, _cache] call bulwark_fnc_spawnLimited;
    if (isNull _group) exitWith {grpNull};
    // Group creation may yield after capacity was granted. Do not retain a team
    // whose cache/owning wave disappeared while the engine was creating it.
    if (!alive _cache || {!([_wave] call bulwark_fnc_waveActive)}) exitWith {
        {deleteVehicle _x} forEach units _group;
        deleteGroup _group;
        grpNull
    };
    _group deleteGroupWhenEmpty true;
    {
        _x setSkill 0.7;
        _x setVariable ["killPointMulti", 2];
        _x setVariable ["points", []];
        _x setVariable ["bw_stationary", _defend, true];
        _x setVariable ["aiMode", if (_defend) then {"NonCQB"} else {"rush"}];
        _x addEventHandler ["Hit", killPoints_fnc_hit];
        _x addEventHandler ["Killed", killPoints_fnc_killed];
        (waveUnits select 0) pushBack _x;
    } forEach units _group;
    if (!isNil "mainZeus") then {mainZeus addCuratorEditableObjects [units _group, true]};
    _group setVariable ["bw_scriptedMovement", _defend, true];
    if (_defend) then {
        [_group, _location, 75] call lambs_wp_fnc_taskPatrol;
    } else {[_group, _wave] call bulwark_fnc_controlEnemyGroup};
    _group
};
private _groups = [];
for "_i" from 1 to 3 do {
    if (!alive _cache || {!([_wave] call bulwark_fnc_waveActive)}) exitWith {};
    private _group = [_location, _side, _classes, true] call _spawnTeam;
    if (!isNull _group) then {_groups pushBack _group};
};
private _nextSpawn = time + 125;
while {alive _cache && {[_wave] call bulwark_fnc_waveActive}} do {
    if (time >= _nextSpawn) then {
        private _group = [_location, _side, _classes, false] call _spawnTeam;
        if (!isNull _group) then {_groups pushBack _group};
        _nextSpawn = time + 125;
    };
    sleep 1;
};
BW_ACTIVE_FOBS = BW_ACTIVE_FOBS - [_cache];
deleteMarker _marker;
[] call bulwark_fnc_tacticalState;
if (!alive _cache && {[_wave] call bulwark_fnc_waveActive}) then {
    ["TaskSucceeded", ["Enemy FOB", "Reinforcements stopped."]] remoteExec ["BIS_fnc_showNotification", 0];
};
// Cancellation owns cleanup; a destroyed cache during combat releases defenders.
if !([_wave] call bulwark_fnc_waveActive) exitWith {
    {{deleteVehicle _x} forEach units _x; deleteGroup _x} forEach _groups;
    {deleteVehicle _x} forEach _objects;
};
// Existing defenders continue the fight but no longer guard an objective.
{
    {_x setVariable ["bw_stationary", false, true]; _x setVariable ["aiMode", "rush"]} forEach units _x;
    [_x, true, true] call lambs_wp_fnc_taskReset;
    _x setVariable ["bw_scriptedMovement", false, true];
    [_x, _wave] call bulwark_fnc_controlEnemyGroup;
} forEach _groups;
// The registered producer must finish after handoff, otherwise the mission waits
// for this job while this job waits for the wave. Keep scenery until intermission.
[_objects, _wave] spawn {
    params ["_objects", "_wave"];
    waitUntil {sleep 1; !([_wave] call bulwark_fnc_waveActive)};
    {deleteVehicle _x} forEach _objects;
};
