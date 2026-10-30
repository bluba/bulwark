// Return a clear ground position in ASL, or [] so callers can retry safely.
params ["_spawnObject", ["_unit", objNull]];
if (isNull _spawnObject) exitWith {[]};
private _bounds = boundingBoxReal _spawnObject;
private _minimum = _bounds select 0;
private _maximum = _bounds select 1;
private _halfX = abs (_minimum select 0) max abs (_maximum select 0);
private _halfY = abs (_minimum select 1) max abs (_maximum select 1);
// Circumscribe the whole footprint, regardless of the truck's rotation.
private _clearance = 12 max (sqrt (_halfX * _halfX + _halfY * _halfY) + 6);
private _class = if (isNull _unit) then {"B_Soldier_F"} else {typeOf _unit};
private _startAngle = getDir _spawnObject + 90 + random 30;
private _found = [];
private _safe = {
    params ["_position"];
    if (_position isEqualTo [] || {(_position select 0) <= 0} || {(_position select 1) <= 0} ||
        {(_position select 0) >= worldSize} || {(_position select 1) >= worldSize} || {surfaceIsWater _position} ||
        {_position distance2D _spawnObject < _clearance}) exitWith {false};
    // findEmptyPosition ignores moving objects, so check their swept footprints.
    private _vehicles = nearestObjects [_position, ["LandVehicle", "Air", "Ship"], 60];
    _vehicles pushBackUnique _spawnObject;
    if ((_vehicles findIf {
        private _box = boundingBoxReal _x;
        private _lo = _box select 0;
        private _hi = _box select 1;
        private _rx = abs (_lo select 0) max abs (_hi select 0);
        private _ry = abs (_lo select 1) max abs (_hi select 1);
        private _radius = sqrt (_rx * _rx + _ry * _ry) + 2;
        if (_x isEqualTo _spawnObject) then {_radius = _radius max _clearance};
        private _origin = getPosATL _x;
        private _travel = (velocity _x) vectorMultiply 3;
        private _dx = _travel select 0;
        private _dy = _travel select 1;
        private _lengthSq = _dx * _dx + _dy * _dy;
        private _fraction = 0;
        if (_lengthSq > 0.01) then {
            _fraction = ((((_position select 0) - (_origin select 0)) * _dx +
                ((_position select 1) - (_origin select 1)) * _dy) / _lengthSq) max 0 min 1;
        };
        _position distance2D (_origin vectorAdd (_travel vectorMultiply _fraction)) < _radius
    }) >= 0) exitWith {false};
    if (((_position nearEntities ["CAManBase", 2]) findIf {_x != _unit && {alive _x}}) >= 0) exitWith {false};
    private _feet = ATLToASL [_position select 0, _position select 1, 0.2];
    !lineIntersects [_feet, _feet vectorAdd [0, 0, 1.8], _unit]
};
{
    private _radius = _clearance + _x;
    for "_angle" from 0 to 337.5 step 22.5 do {
        private _candidate = (_spawnObject getPos [_radius, _startAngle + _angle]) findEmptyPosition [0, 3, _class];
        if ([_candidate] call _safe) exitWith {
            _found = ATLToASL [_candidate select 0, _candidate select 1, 0.2];
        };
    };
    if !(_found isEqualTo []) exitWith {};
} forEach [3, 10, 20, 35, 55, 80];
if (!(_found isEqualTo []) && {!([ASLToATL _found] call _safe)}) then {_found = []};
_found
