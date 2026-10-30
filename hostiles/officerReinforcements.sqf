if (!isServer || {!canSuspend}) exitWith {};
params ["_id"];
private _r = missionNamespace getVariable ["BW_OFFICER_HUNT", createHashMap];
if ((_r getOrDefault ["id",-1]) != _id || {(_r get "state") != "active"}) exitWith {};
private _officer = _r get "officer";
private _wave = _r get "wave";
if (!alive _officer || {!([_wave] call bulwark_fnc_waveActive)}) exitWith {};
private _settings = _r get "settings";
private _classes = [];
for "_i" from 1 to (_settings get "TEAM_SIZE") do {_classes pushBack (selectRandom (_r get "classes"))};
private _deadline = (time + (_settings get "TIMEOUT")) min (_r get "deadline");
private _group = [[_r get "position", _r get "side", _classes], "group", _wave, false, _officer, _deadline] call bulwark_fnc_spawnLimited;
isNil {
    private _current = missionNamespace getVariable ["BW_OFFICER_HUNT", createHashMap];
    private _teams = (_r get "reinforcementGroups") select {!isNull _x && {(units _x findIf {alive _x}) >= 0}};
    private _living = {alive _x && {!(_x getVariable ["bw_stationary", false])}} count (_r get "units");
    if ((_current getOrDefault ["id",-1]) == _id && {(_r get "state") == "active"} &&
        {[_wave] call bulwark_fnc_waveActive} && {alive _officer} && {time < _deadline} &&
        {count _teams < (_settings get "TEAM_CAP")} && {_living + count units _group <= 8} && {!isNull _group} &&
        {count units _group == count _classes}) then {
        _group deleteGroupWhenEmpty true;
        {
            _x setVariable ["bw_officerId", _id, true];
            _x setVariable ["aiMode", "rush", true];
            if (isNil {_x getVariable "killPointMulti"}) then {
                _x setVariable ["points", []];
                _x addEventHandler ["Hit", killPoints_fnc_hit];
                _x addEventHandler ["Killed", killPoints_fnc_killed];
            };
            _x setVariable ["killPointMulti", 2, true];
            (waveUnits select 0) pushBackUnique _x;
        } forEach units _group;
        (_r get "units") append (units _group);
        if (!isNil "mainZeus") then {mainZeus addCuratorEditableObjects [units _group, true]};
        _teams pushBack _group;
        _r set ["reinforcementGroups", _teams];
        _group setVariable ["bw_scriptedMovement", false, true];
        [_group, _wave] call bulwark_fnc_controlEnemyGroup;
    } else {{deleteVehicle _x} forEach units _group; deleteGroup _group};
};
