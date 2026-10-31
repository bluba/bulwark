params ["_player", ["_targetPos", []], ["_drone", false]];
if (_drone) exitWith {}; // Retired drone-delivery mode; use the Supplies shop.
if (!isServer || {isNull _player}) exitWith {};
if (count _targetPos < 2) exitWith {
    [_player, "ammoRequest"] remoteExecCall ["BIS_fnc_addCommMenuItem", _player];
    ["Select a delivery location."] remoteExecCall ["hint", _player];
};
private _spawn = [_targetPos, 2000, 2500, 5, 0] call BIS_fnc_findSafePos;
_spawn set [2, 200];
private _class = "B_T_VTOL_01_vehicle_F";
if (!isClass (configFile >> "CfgVehicles" >> _class)) exitWith {
    [_player, "ammoRequest"] remoteExecCall ["BIS_fnc_addCommMenuItem", _player];
};
private _result = [_spawn, _spawn getDir _targetPos, _class, west] call BIS_fnc_spawnVehicle;
_result params ["_aircraft", "_crew", "_group"];
if (isNull _aircraft) exitWith {};
_group setBehaviour "CARELESS";
_group setCombatMode "BLUE";
_aircraft flyInHeight 200;
private _waypoint = _group addWaypoint [_targetPos, 0];
_waypoint setWaypointType "MOVE";
_waypoint setWaypointSpeed "FULL";
private _arrived = [_aircraft, _targetPos, 100, 180] call bulwark_fnc_waitForAircraft;
if (_arrived) then {
    private _position = getPosATL _aircraft;
    _position set [2, ((_position select 2) - 8) max 15];
    private _box = createVehicle ["B_supplyCrate_F", _position, [], 0, "CAN_COLLIDE"];
    clearItemCargoGlobal _box;
    clearWeaponCargoGlobal _box;
    clearMagazineCargoGlobal _box;
    clearBackpackCargoGlobal _box;

    _box addItemCargoGlobal ["Medikit", 2];
    _box addItemCargoGlobal ["FirstAidKit", 6];
    if (attkWave > 5) then {
        {if (isClass (configFile >> "CfgWeapons" >> (_x select 0))) then {
            _box addWeaponCargoGlobal _x;
        }} forEach [["PSZ_RPG7V", 1], ["PSZ_Grom", 3]];
        if (isClass (configFile >> "CfgMagazines" >> "PSZ_PG7VR_THEAT")) then {_box addMagazineCargoGlobal ["PSZ_PG7VR_THEAT", 2]};
    };
    if (attkWave > 10) then {
        if (isClass (configFile >> "CfgWeapons" >> "PSZ_Spike_LR")) then {_box addWeaponCargoGlobal ["PSZ_Spike_LR", 1]};
        if (isClass (configFile >> "CfgMagazines" >> "PSZ_Spike_THEAT")) then {_box addMagazineCargoGlobal ["PSZ_Spike_THEAT", 2]};
    };
    {[_box, _x] execVM "supports\ammoDrop.sqf"} forEach ([] call bulwark_fnc_humanPlayers);
    _box allowDamage false;
    private _parachute = createVehicle ["B_Parachute_02_F", _position, [], 0, "FLY"];
    _box attachTo [_parachute, [0, 0, 0]];
    private _deadline = time + 120;
    waitUntil {sleep 0.2; isNull _box || {isNull _parachute} || {(getPosATL _box select 2) < 4} || {time >= _deadline}};
    if (!isNull _box) then {
        detach _box;
        if ((getPosATL _box select 2) > 4) then {_box setPosATL [_targetPos select 0, _targetPos select 1, 0]};
        _box setVariable ["spawnWave", attkWave];
        "SmokeShellBlue" createVehicle (getPosATL _box);
        if (!isNil "mainZeus") then {mainZeus addCuratorEditableObjects [[_box], true]};
    };
    deleteVehicle _parachute;
} else {["Supply aircraft lost or unable to reach the drop zone."] remoteExecCall ["hint", _player]};
{deleteVehicle _x} forEach _crew;
deleteVehicle _aircraft;
deleteGroup _group;
