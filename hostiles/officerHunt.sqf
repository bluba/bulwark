if (!isServer || {!canSuspend}) exitWith {};
params ["_id"];
private _r = missionNamespace getVariable ["BW_OFFICER_HUNT", createHashMap];
if ((_r getOrDefault ["id",-1]) != _id) exitWith {};
private _wave = _r get "wave";
private _settings = _r get "settings";
private _position = [([] call bulwark_fnc_spawnAnchor)] call bulwark_fnc_findOfficerPost;
if (_position isEqualTo []) exitWith {[_id,"placementFailed"] call bulwark_fnc_endOfficerHunt};
private _classes = [_r get "officerClass"];
for "_i" from 1 to (_settings get "GUARDS") do {_classes pushBack (selectRandom (_r get "classes"))};
private _deadline = time + (_settings get "TIMEOUT");
private _group = [[_position, _r get "side", _classes], "group", _wave, false, objNull, _deadline] call bulwark_fnc_spawnLimited;
private _activated = false;
isNil {
    private _current = missionNamespace getVariable ["BW_OFFICER_HUNT", createHashMap];
    private _players = ([] call bulwark_fnc_humanPlayers) select {alive _x};
    if ((_current getOrDefault ["id",-1]) == _id && {(_current get "state") == "settingUp"} &&
        {[_wave] call bulwark_fnc_waveActive} && {time < _deadline} && {!isNull _group} &&
        {count units _group == count _classes} && {({alive _x} count units _group) == count _classes} &&
        {(_players findIf {_x distance2D _position < 200}) < 0} &&
        {isNil "bulwarkBox" || {isNull bulwarkBox} || {bulwarkBox distance2D _position >= 200}}) then {
        private _officer = (units _group) select 0;
        _group deleteGroupWhenEmpty true;
        _group selectLeader _officer;
        _group setVariable ["bw_officerId", _id, true];
        _group setVariable ["bw_officerActive", true, true];
        _group setVariable ["bw_scriptedMovement", true, true];
        {
            _x setVariable ["bw_officerId", _id, true];
            _x setVariable ["bw_stationary", true, true];
            _x setVariable ["aiMode", "NonCQB", true];
            if (isNil {_x getVariable "killPointMulti"}) then {
                _x setVariable ["points", []];
                _x addEventHandler ["Hit", killPoints_fnc_hit];
                _x addEventHandler ["Killed", killPoints_fnc_killed];
            };
            _x setVariable ["killPointMulti", 2, true];
            (waveUnits select 0) pushBackUnique _x;
        } forEach units _group;
        _current set ["units", +(units _group)];
        if (!isNil "mainZeus") then {mainZeus addCuratorEditableObjects [units _group, true]};
        _current set ["postGroup", _group];
        _current set ["officer", _officer];
        _current set ["position", _position];
        _current set ["deadline", time + (_settings get "LIFETIME")];
        _current set ["nextRequest", time + (_settings get "INTERVAL")];
        _current set ["state", "active"];
        BW_OFFICER_LAST_WAVE = _wave;
        private _center = _position getPos [random 75, random 360];
        missionNamespace setVariable ["BW_OFFICER_STATUS", [_id, _wave, _center, 150, serverTime + (_settings get "LIFETIME")], true];
        _activated = true;
    } else {{deleteVehicle _x} forEach units _group; deleteGroup _group};
};
if (!_activated) exitWith {[_id,"setupFailed"] call bulwark_fnc_endOfficerHunt};
["active"] remoteExecCall ["bulwark_fnc_officerNotice", 0];
while {(_r get "state") == "active"} do {
    [] call bulwark_fnc_updateOfficerHunt;
    if ((_r get "state") == "active" && {time >= (_r get "nextRequest")}) then {
        private _teams = (_r get "reinforcementGroups") select {!isNull _x && {(units _x findIf {alive _x}) >= 0}};
        _r set ["reinforcementGroups", _teams];
        _r set ["nextRequest", time + (_settings get "INTERVAL")];
        if (count _teams < (_settings get "TEAM_CAP") && {scriptDone (_r get "pendingJob")}) then {
            isNil {
                if ((_r get "state") == "active" && {alive (_r get "officer")}) then {
                    _r set ["pendingJob", [[_id], "hostiles\officerReinforcements.sqf"] call bulwark_fnc_queueHostiles];
                };
            };
        };
    };
    sleep 1;
};
// Do not terminate a child inside the capacity gateway: let its reservation drain.
waitUntil {sleep 0.1; scriptDone (_r get "pendingJob")};
