// Scheduled VTOL -> parachute -> smoke delivery, matching the active ammo support.
// Every asset is registered atomically in the owning record before any wait.
// Returns "" on landing, otherwise a terminal reason for the owning worker.
params ["_id", ["_family", "medical"]];
if (!isServer || {isRemoteExecuted} || {!canSuspend}) exitWith {"invalidDeliveryContext"};
private _keys = [_family] call loot_fnc_supplyFamily;
if (_keys isEqualTo []) exitWith {"invalidFamily"};
private _recordKey = _keys select 0;
private _deliveryKey = _keys select 7;
private _record = missionNamespace getVariable [_recordKey, createHashMap];
if ((_record getOrDefault ["id", -1]) != _id) exitWith {"deliveryCancelled"};
private _wave = _record get "wave";
private _target = +(_record get "site");
private _anchor = _record get "anchorObject";
private _origin = _record get "anchorPosition";
private _relocation = _record get "relocation";
private _airClass = missionNamespace getVariable ["BW_SUPPLY_AIRCRAFT", "B_T_VTOL_01_vehicle_F"];
private _transit = missionNamespace getVariable ["BW_SUPPLY_DELIVERY_TIMEOUT", 180];
private _descent = missionNamespace getVariable ["BW_SUPPLY_DESCENT_TIMEOUT", 120];
if (!(_airClass isEqualType "") || {!(_transit isEqualType 0)} || {!(_descent isEqualType 0)} ||
    {!finite _transit} || {!finite _descent} || {_transit <= 0} || {_transit > 300} || {_descent <= 0} || {_descent > 180}) exitWith {"invalidDeliveryConfig"};
if (!isClass (configFile >> "CfgVehicles" >> _airClass) ||
    {!(_airClass isKindOf ["Air", configFile >> "CfgVehicles"])} ||
    {!isClass (configFile >> "CfgVehicles" >> "B_Parachute_02_F")}) exitWith {"missingDeliveryClass"};
private _valid = {
    private _current = missionNamespace getVariable [_recordKey, createHashMap];
    (_current getOrDefault ["id", -1]) == _id && {[_wave] call bulwark_fnc_waveActive} &&
    {!isNull _anchor} && {_anchor isEqualTo bulwarkBox} && {_anchor distance2D _origin < _relocation}
};
if (!(call _valid)) exitWith {"deliveryCancelled"};
private _spawn = [];
private _bearing = random 360;
for "_i" from 0 to 7 do {
    private _angle = _bearing + _i * 45;
    private _distance = 2000 + random 500;
    private _candidate = [(_target select 0) + sin _angle * _distance, (_target select 1) + cos _angle * _distance, 200];
    if ((_candidate select 0) > 0 && {(_candidate select 1) > 0} &&
        {(_candidate select 0) < worldSize} && {(_candidate select 1) < worldSize}) exitWith {_spawn = _candidate};
};
if (_spawn isEqualTo []) exitWith {"noAircraftSpawn"};
private _aircraft = objNull;
private _group = grpNull;
isNil {
    if (call _valid) then {
        private _flight = [_spawn, _spawn getDir _target, _airClass, west] call BIS_fnc_spawnVehicle;
        _flight params ["_vehicle", "_crew", "_flightGroup"];
        _record set ["aircraft", _vehicle];
        _record set ["crew", _crew];
        _record set ["group", _flightGroup];
        _aircraft = _vehicle;
        _group = _flightGroup;
        missionNamespace setVariable [_deliveryKey, [_id, _target, _wave, serverTime + _transit, "inbound"], true];
    };
};
if (isNull _aircraft || {isNull _group}) exitWith {"aircraftSpawnFailed"};
{_x allowFleeing 0} forEach units _group;
_group setBehaviour "CARELESS";
_group setCombatMode "BLUE";
_aircraft flyInHeight 200;
private _waypoint = _group addWaypoint [_target, 0];
_waypoint setWaypointType "MOVE";
_waypoint setWaypointSpeed "FULL";
if (!([_aircraft, _target, 50, _transit, _wave, _valid] call bulwark_fnc_waitForAircraft)) exitWith {
    if (call _valid) then {"aircraftLostOrTimeout"} else {"deliveryCancelled"}
};
private _crate = objNull;
private _parachute = objNull;
isNil {
    if (call _valid) then {
        private _position = getPosATL _aircraft;
        _position set [2, ((_position select 2) - 8) max 15];
        _parachute = createVehicle ["B_Parachute_02_F", _position, [], 0, "FLY"];
        _record set ["parachute", _parachute];
        _crate = createVehicle [_record get "class", _position, [], 0, "CAN_COLLIDE"];
        _record set ["crate", _crate];
        if (!isNull _crate && {!isNull _parachute}) then {
            _crate setVariable ["bw_supplyCacheId", _id, true];
            _crate setVariable ["bw_supplyFamily", _family, true];
            _crate allowDamage false;
            // No stock can be collected before safe landing/publication.
            clearItemCargoGlobal _crate;
            clearMagazineCargoGlobal _crate;
            clearWeaponCargoGlobal _crate;
            clearBackpackCargoGlobal _crate;
            _crate attachTo [_parachute, [0,0,0]];
            _record set ["state", "descending"];
            missionNamespace setVariable [_deliveryKey, [_id, _target, _wave, serverTime + _descent, "descending"], true];
        };
    };
};
if (isNull _crate || {isNull _parachute}) exitWith {"releaseFailed"};
// Fly clear while the supplies descend, like the support aircraft.
private _exit = _target vectorAdd ((_target vectorDiff _spawn) vectorMultiply 2);
_exit set [2, 200];
private _depart = _group addWaypoint [_exit, 0];
_depart setWaypointType "MOVE";
_depart setWaypointSpeed "FULL";
_group setCurrentWaypoint _depart;
private _deadline = time + _descent;
waitUntil {
    sleep 0.2;
    !(call _valid) || {!alive _crate} || {!alive _parachute} ||
    {time >= _deadline} || {(getPosATL _crate select 2) < 4}
};
if (!(call _valid)) exitWith {"deliveryCancelled"};
if (!alive _crate || {!alive _parachute && {(getPosATL _crate select 2) >= 4}}) exitWith {"descentLost"};
if (time >= _deadline) exitWith {"descentTimeout"};
// Check actual landing, not just the intended zone; never teleport a failed drop.
private _ground = getPosATL _crate;
_ground set [2,0];
private _landing = [_ground, _origin, 100, 350, false, _crate, _parachute] call loot_fnc_supplySiteClear;
if (_landing isEqualTo [] || {_ground distance2D _target > 60}) exitWith {"unsafeLanding"};
private _landed = false;
isNil {
    private _excluded = [_family] call loot_fnc_supplyExclusions;
    if ((call _valid) && {(_excluded findIf {_landing distance2D _x < 20}) < 0}) then {
        detach _crate;
        _crate setPosATL _landing;
        _crate enableSimulationGlobal false;
        _record set ["site", getPosATL _crate];
        _record set ["state", "landed"];
        private _smoke = "SmokeShellBlue" createVehicle (getPosATL _crate);
        _record set ["smoke", _smoke];
        [_record] call loot_fnc_cleanupSupplyDelivery;
        _landed = true;
    };
};
if (!_landed) exitWith {"landingCancelledOrConflict"};
""
