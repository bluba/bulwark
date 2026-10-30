/* Idle hosted editor with mission functions loaded:
   [] execVM "tests\respawnClearance.sqf";
   Tests the real ASL placement helper with temporary trucks and a blocking vehicle.
   Dedicated-server concurrent respawns and live driving still need multiplayer tests. */
if (!isServer || {!hasInterface} || {!canSuspend} || {!alive player}) exitWith {};
if (missionNamespace getVariable ["runMissionLoop", false]) exitWith {diag_log "Respawn tests require an idle mission loop"};
BW_respawnClearanceFailures = [];
private _check = {
    params ["_ok", "_message"];
    if (!_ok) then {BW_respawnClearanceFailures pushBack _message; diag_log ("RESPAWN TEST FAILED: " + _message)};
};
[([objNull, player] call bulwark_fnc_findPlaceAround) isEqualTo [], "Missing truck returns no position, not world origin"] call _check;
private _center = [getPosATL player, 300, 500, 15, 0] call BIS_fnc_findSafePos;
private _classes = ["B_Truck_01_transport_F"];
if (isClass (configFile >> "CfgVehicles" >> "PSZ_PL_WDL10_Star_1466")) then {_classes pushBack "PSZ_PL_WDL10_Star_1466"};
{
    private _class = _x;
    private _truck = createVehicle [_class, _center, [], 0, "NONE"];
    _truck allowDamage false;
    private _box = boundingBoxReal _truck;
    private _lo = _box select 0;
    private _hi = _box select 1;
    private _rx = abs (_lo select 0) max abs (_hi select 0);
    private _ry = abs (_lo select 1) max abs (_hi select 1);
    private _clearance = 12 max (sqrt (_rx * _rx + _ry * _ry) + 6);
    {
        _truck setDir _x;
        private _position = [_truck, player] call bulwark_fnc_findPlaceAround;
        [!(_position isEqualTo []), format ["%1 heading %2 finds clear ground", _class, _x]] call _check;
        if !(_position isEqualTo []) then {
            [_position distance2D _truck >= _clearance, "Position clears whole rotated footprint plus buffer"] call _check;
            private _atl = ASLToATL _position;
            [abs ((_atl select 2) - 0.2) < 0.01, "Result is ground ASL, not truck-floor height"] call _check;
            [!surfaceIsWater _atl, "Position is on land"] call _check;
        };
    } forEach [0, 45, 90, 180];

    // A candidate occupied by another vehicle must not be reused.
    private _first = [_truck, player] call bulwark_fnc_findPlaceAround;
    if !(_first isEqualTo []) then {
        private _blocker = createVehicle ["B_MRAP_01_F", ASLToATL _first, [], 0, "NONE"];
        private _next = [_truck, player] call bulwark_fnc_findPlaceAround;
        if !(_next isEqualTo []) then {[_next distance2D _blocker > 3, "Blocking vehicle is avoided"] call _check};
        deleteVehicle _blocker;
    };
    // Sample in one unscheduled block so simulation cannot change the test velocity.
    private _movingPosition = [];
    private _future = [];
    isNil {
        _truck setVelocity [0, 10, 0];
        _future = (getPosATL _truck) vectorAdd ((velocity _truck) vectorMultiply 3);
        _movingPosition = [_truck, player] call bulwark_fnc_findPlaceAround;
        _truck setVelocity [0, 0, 0];
    };
    if !(_movingPosition isEqualTo []) then {
        [_movingPosition distance2D _future >= _clearance, "Position also clears predicted three-second truck location"] call _check;
    };
    deleteVehicle _truck;
} forEach _classes;
diag_log format ["RESPAWN CLEARANCE REGRESSION COMPLETE: %1 failures", count BW_respawnClearanceFailures];
