params ["_id"];
if (!isServer || {!canSuspend}) exitWith {};
private _r = missionNamespace getVariable ["BW_FPV_OPERATOR",createHashMap];
if ((_r getOrDefault ["id",-1]) != _id) exitWith {};
private _wave = _r get "wave";
private _s = _r get "settings";
private _origin = _r get "origin";
private _sites = ([] call bulwark_fnc_fpvSites) select {_x distance2D _origin >= 300 && {_x distance2D _origin <= 700}};
["siteSearch",[_id,count _sites,_origin]] call bulwark_fnc_fpvLog;
private _position = [];
{
    private _p = +_x; _p set [2,0];
    if ([_p,_origin,objNull,true] call bulwark_fnc_fpvSiteClear) exitWith {_position = _p};
} forEach (([_sites] call BIS_fnc_arrayShuffle) select [0,96]);
if (_position isEqualTo []) exitWith {[_id,"noSite"] call bulwark_fnc_endFpv};
private _side = if (missionNamespace getVariable ["defectorWave",false]) then {resistance} else {east};
private _pool = missionNamespace getVariable [if (_side == resistance) then {"DEFECTOR_INF"} else {"HOSTILE_LEVEL_2"},[]];
if (!(_pool isEqualType [])) exitWith {[_id,"invalidInfantry"] call bulwark_fnc_endFpv};
_pool = _pool select {_x isEqualType "" && {isClass (configFile >> "CfgVehicles" >> _x)} && {_x isKindOf ["Man",configFile >> "CfgVehicles"]}};
if (_pool isEqualTo []) exitWith {[_id,"noInfantry"] call bulwark_fnc_endFpv};
private _device = objNull;
isNil {
    if ((_r get "state") == "setup" && {[_wave] call bulwark_fnc_waveActive}) then {
        _device = createVehicle ["Box_East_Ammo_F",_position,[],0,"NONE"];
        _r set ["device",_device];
        _device setVariable ["bw_fpvId",_id,true];
        clearWeaponCargoGlobal _device; clearMagazineCargoGlobal _device;
        clearItemCargoGlobal _device; clearBackpackCargoGlobal _device;
    };
};
if (isNull _device) exitWith {[_id,"cancelled"] call bulwark_fnc_endFpv};
private _classes = [];
for "_i" from 0 to (_s get "GUARDS") do {_classes pushBack selectRandom _pool};
private _group = [[_position vectorAdd [3,0,0],_side,_classes],"group",_wave,false,_device,time + (_s get "SETUP_TIMEOUT")] call bulwark_fnc_spawnLimited;
private _activated = false;
isNil {
    if ((_r get "state") == "setup" && {[_wave] call bulwark_fnc_waveActive} && {alive _device} &&
        {!isNull _group} && {count units _group == count _classes} && {({alive _x} count units _group) == count _classes} &&
        {[_position,_origin,_device] call bulwark_fnc_fpvSiteClear} && {bulwarkBox isEqualTo (_r get "anchor")} &&
        {bulwarkBox distance2D _origin < 150}) then {
        _r set ["group",_group]; _r set ["units",+(units _group)];
        _r set ["operator",(units _group) select 0]; _r set ["side",_side]; _r set ["position",_position];
        _group setVariable ["bw_fpvId",_id,true]; _group setVariable ["bw_fpvActive",true,true];
        _group setVariable ["bw_scriptedMovement",true,true]; _group deleteGroupWhenEmpty true;
        {
            _x setVariable ["bw_stationary",true,true]; _x setVariable ["aiMode","NonCQB",true];
            if (isNil {_x getVariable "killPointMulti"}) then {
                _x setVariable ["points",[]];
                _x addEventHandler ["Hit",killPoints_fnc_hit]; _x addEventHandler ["Killed",killPoints_fnc_killed];
            };
            _x setVariable ["killPointMulti",2,true]; (waveUnits select 0) pushBackUnique _x;
        } forEach units _group;
        _r set ["deadline",time + (_s get "LIFETIME")]; _r set ["nextSpawn",time + (_s get "FIRST_DELAY")];
        _r set ["state","active"]; BW_FPV_LAST_WAVE = _wave;
        missionNamespace setVariable ["BW_FPV_STATUS",[_id,_wave,_position getPos [random 75,random 360],150,serverTime + (_s get "LIFETIME")],true];
        _activated = true;
    } else {{deleteVehicle _x} forEach units _group; deleteGroup _group};
};
if (!_activated) exitWith {[_id,"setupFailed"] call bulwark_fnc_endFpv};
["stationActive",[_id,_position,_r get "operator",_device,_r get "deadline"]] call bulwark_fnc_fpvLog;
["active"] remoteExecCall ["bulwark_fnc_fpvNotice",0];
private _nextMonitor = 0;
while {(_r get "state") == "active"} do {
    if (time >= _nextMonitor) then {[] call bulwark_fnc_updateFpv; _nextMonitor = time + 1};
    // Death and cancellation checked every movement tick, not only the UI tick.
    if (!alive (_r get "operator") || {!alive _device} || {!([_wave] call bulwark_fnc_waveActive)}) then {[_id,"destroyed"] call bulwark_fnc_endFpv};
    if ((_r get "state") == "active") then {
        if (time >= (_r get "nextSpawn")) then {
            _r set ["nextSpawn",time + (_s get "INTERVAL_MIN") + random ((_s get "INTERVAL_MAX") - (_s get "INTERVAL_MIN"))];
            [_r] call bulwark_fnc_fpvSpawnDrone;
        };
        [_r] call bulwark_fnc_fpvTick;
    };
    sleep 0.1;
};
