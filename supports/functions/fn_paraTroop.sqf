params ["_player", ["_targetPos", []], "_unitCount", "_aircraftClass", "_classList"];
if (!isServer || {isNull _player}) exitWith {};
private _validClasses = _classList select {isClass (configFile >> "CfgVehicles" >> _x)};
if (count _targetPos < 2 || {_validClasses isEqualTo []} ||
    {!isClass (configFile >> "CfgVehicles" >> _aircraftClass)}) exitWith {
    [_player, "paraDrop"] remoteExecCall ["BIS_fnc_addCommMenuItem", _player];
};
private _spawn = _targetPos getPos [1500, random 360];
_spawn set [2, 200];
private _result = [_spawn, _spawn getDir _targetPos, _aircraftClass, west] call BIS_fnc_spawnVehicle;
_result params ["_aircraft", "_crew", "_flightGroup"];
if (isNull _aircraft) exitWith {};
_flightGroup setBehaviour "CARELESS";
_aircraft flyInHeight 150;
private _waypoint = _flightGroup addWaypoint [_targetPos, 0];
_waypoint setWaypointSpeed "FULL";
if ([_aircraft, _targetPos, 250, 180] call bulwark_fnc_waitForAircraft) then {
    private _troops = createGroup [west, true];
    for "_i" from 1 to _unitCount do {
        if (!alive _aircraft || {missionNamespace getVariable ["missionExtract", false]}) exitWith {};
        private _position = getPosATL _aircraft;
        private _unit = _troops createUnit [selectRandom _validClasses, _targetPos, [], 0, "NONE"];
        if (!isNull _unit) then {
            _unit setVariable ["bw_purchaseOwner", getPlayerUID _player, true];
            _unit setVariable ["bw_allyGroup", _troops, true];
            removeBackpack _unit;
            _unit addBackpack "B_Parachute";
            _unit setPosATL (_position vectorAdd [0, 0, -5]);
            _unit action ["OpenParachute", _unit];
            _unit setSkill 0.8;
            _unit addEventHandler ["Killed", {
                params ["_unit"];
                removeVest _unit;
                removeBackpack _unit;
                removeAllWeapons _unit;
                removeAllAssignedItems _unit;
            }];
        };
        sleep 0.7;
    };
    if (!isNil "mainZeus") then {mainZeus addCuratorEditableObjects [units _troops, true]};
    // Keep reinforcements autonomous so the Bulwark controller cannot override players.
    // Wait for insertion before handing movement to the ground-duty controller.
    private _landingDeadline = time + 120;
    waitUntil {
        sleep 1;
        (units _troops findIf {alive _x && {!isTouchingGround _x}}) < 0 ||
        {time >= _landingDeadline} || {missionNamespace getVariable ["missionExtract", false]}
    };
    if ((units _troops findIf {alive _x}) >= 0 && {!(missionNamespace getVariable ["missionExtract", false])}) then {
        [_troops, leader _troops, _player] call bulwark_fnc_followBulwark;
    } else {if (units _troops isEqualTo []) then {deleteGroup _troops}};
};
{deleteVehicle _x} forEach _crew;
deleteVehicle _aircraft;
deleteGroup _flightGroup;
