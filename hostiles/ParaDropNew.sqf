if (!isServer) exitWith {};
params [["_wave", attkWave]];
if !([_wave] call bulwark_fnc_waveActive) exitWith {};
private _target = [] call bulwark_fnc_spawnAnchor;
private _spawn = [_target, 2000, 2500, 5, 0] call BIS_fnc_findSafePos;
_spawn set [2, 150];
private _aircraftClass = "RHS_TU95MS_vvs_tambov";
private _classes = ["rhs_vdv_sergeant", "rhs_vdv_medic", "rhs_vdv_arifleman", "rhs_vdv_arifleman_rpk", "rhs_vdv_rifleman", "rhs_vdv_LAT"] select {
    isClass (configFile >> "CfgVehicles" >> _x)
};
if (_classes isEqualTo [] || {!isClass (configFile >> "CfgVehicles" >> _aircraftClass)}) exitWith {};
private _result = [[_spawn, _spawn getDir _target, _aircraftClass, east], "vehicle", _wave, false] call bulwark_fnc_spawnLimited;
_result params ["_aircraft", "_crew", "_flightGroup"];
if (isNull _aircraft) exitWith {};
_aircraft setVariable ["bw_scriptedTransport", true, true];
_flightGroup setVariable ["bw_scriptedMovement", true, true];
_flightGroup setBehaviour "CARELESS";
_aircraft flyInHeight 150;
private _waypoint = _flightGroup addWaypoint [_target, 0];
_waypoint setWaypointSpeed "FULL";
if ([_aircraft, _target, 250, 120, _wave] call bulwark_fnc_waitForAircraft) then {
    private _count = ceil ((1 + random (_wave / 4)) * 5);
    private _troops = createGroup [east, true];
    _troops setVariable ["bw_scriptedMovement", true, true];
    for "_i" from 1 to _count do {
        if (!alive _aircraft || {!([_wave] call bulwark_fnc_waveActive)}) exitWith {};
        private _unit = [[_troops, [selectRandom _classes, _target, [], 0, "NONE"]], "unit", _wave, false, _aircraft] call bulwark_fnc_spawnLimited;
        if (isNull _unit) exitWith {};
        // Capacity may have held this request after the aircraft passed the DZ.
        // Keep the pending troop inactive until a bounded return pass succeeds.
        isNil {
            _unit setVariable ["killPointMulti", 2];
            _unit setVariable ["points", []];
            _unit addEventHandler ["Hit", killPoints_fnc_hit];
            _unit addEventHandler ["Killed", killPoints_fnc_killed];
            _unit setVariable ["aiMode", "rush"];
            _unit hideObjectGlobal true;
            _unit enableSimulationGlobal false;
            _unit allowDamage false;
        };
        private _atDropZone = true;
        if (_aircraft distance2D _target > 250) then {
            for "_wp" from (count waypoints _flightGroup - 1) to 0 step -1 do {deleteWaypoint [_flightGroup, _wp]};
            private _returnWaypoint = _flightGroup addWaypoint [_target, 0];
            _returnWaypoint setWaypointSpeed "FULL";
            _flightGroup setCurrentWaypoint _returnWaypoint;
            _atDropZone = [_aircraft, _target, 250, 120, _wave] call bulwark_fnc_waitForAircraft;
        };
        private _dropped = false;
        // Recheck and place without suspension: no stale aircraft position or
        // ground infantry is exposed if the carrier/wave disappears in transit.
        isNil {
            if (_atDropZone && {alive _unit} && {alive _aircraft} && {[_wave] call bulwark_fnc_waveActive} && {_aircraft distance2D _target <= 250}) then {
                removeBackpack _unit;
                _unit addBackpack "B_Parachute";
                _unit setPosATL ((getPosATL _aircraft) vectorAdd [0, 0, -5]);
                _unit allowDamage true;
                _unit enableSimulationGlobal true;
                _unit hideObjectGlobal false;
                _unit action ["OpenParachute", _unit];
                (waveUnits select 0) pushBack _unit;
                _dropped = true;
            } else {deleteVehicle _unit};
        };
        if (!_dropped) exitWith {};
        sleep 0.7;
    };
    if (!isNil "mainZeus") then {mainZeus addCuratorEditableObjects [units _troops, true]};
    _troops setVariable ["bw_scriptedMovement", false, true];
    [_troops, _wave] call bulwark_fnc_controlEnemyGroup;
    if (units _troops isEqualTo []) then {deleteGroup _troops};
};
{deleteVehicle _x} forEach _crew;
deleteVehicle _aircraft;
deleteGroup _flightGroup;
