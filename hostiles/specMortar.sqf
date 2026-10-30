if (!isServer) exitWith {};
params [["_wave", attkWave]];
if !([_wave] call bulwark_fnc_waveActive) exitWith {};
private _side = if (defectorWave) then {resistance} else {east};
private _position = [([] call bulwark_fnc_spawnAnchor), BULWARK_RADIUS - 15, BULWARK_RADIUS - 5, 3, 0, 10, 0] call BIS_fnc_findSafePos;
private _result = [[_position, 0, "O_Mortar_01_F", _side], "vehicle", _wave, false] call bulwark_fnc_spawnLimited;
_result params ["_mortar", "_crew", "_group"];
if (isNull _mortar) exitWith {};
{
    _x setVariable ["bw_stationary", true, true];
    _x setVariable ["aiMode", "NonCQB"];
    _x setVariable ["killPointMulti", HOSTILE_CAR_POINT_SCORE];
    _x setVariable ["points", []];
    _x addEventHandler ["Hit", killPoints_fnc_hit];
    _x addEventHandler ["Killed", killPoints_fnc_killed];
    (waveUnits select 0) pushBack _x;
} forEach _crew;
if (!isNil "mainZeus") then {mainZeus addCuratorEditableObjects [[_mortar], true]};
private _nextShot = time + 23;
while {alive _mortar && {({alive _x} count _crew) > 0} && {[_wave] call bulwark_fnc_waveActive}} do {
    if (time >= _nextShot) then {
        private _target = [] call bulwark_fnc_spawnAnchor;
        _target = _target vectorAdd [random [-45, 0, 45], random [-45, 0, 45], 0];
        if (_target inRangeOfArtillery [[_mortar], "8Rnd_82mm_Mo_shells"]) then {
            _mortar doArtilleryFire [_target, "8Rnd_82mm_Mo_shells", 1];
        };
        _nextShot = time + 30;
    };
    sleep 1;
};
if !([_wave] call bulwark_fnc_waveActive) exitWith {
    {deleteVehicle _x} forEach _crew;
    deleteVehicle _mortar;
    deleteGroup _group;
};
if ((_crew findIf {alive _x}) < 0) exitWith {};
// A surviving gunner must lose both controller exclusions after mortar loss.
{
    _x setVariable ["bw_stationary", false, true];
    _x setVariable ["aiMode", "rush", true];
} forEach _crew;
_group setVariable ["bw_baseMode", "rush", true];
if (local _group) then {[_group, _wave] call bulwark_fnc_controlEnemyGroup} else {
    [_group, _wave] remoteExecCall ["bulwark_fnc_controlEnemyGroup", groupOwner _group];
};
