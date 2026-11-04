// Vehicle/NPC placement guard; only other vehicles and players are obstacles.
params ["_object", "_position", ["_snapToGround", false]];
missionNamespace setVariable ["BW_PLACEMENT_BLOCKER", ""];
// Only vehicles and NPCs use clearance restrictions. Construction and crates
// retain unrestricted placement and vertical adjustment, including stacking.
private _restricted = (_object isKindOf "LandVehicle") ||
    {_object isKindOf "Air"} || {_object isKindOf "Ship"} || {_object isKindOf "Man"};
if (!_restricted) exitWith {true};
// Placement is checked before detach. The carrier's bounding box can overlap
// the held preview; it must not prevent releasing that same object.
// Do not ignore other players or the carrier's vehicle.
private _carrier = attachedTo _object;
if (!(_carrier isKindOf "Man")) then {_carrier = objNull};
private _delta = (ATLToASL _position) vectorDiff (ATLToASL (getPosATL _object));
private _bounds = {
    params ["_entity", "_offset"];
    private _box = boundingBoxReal _entity;
    private _min = _box select 0;
    private _max = _box select 1;
    private _xs = [];
    private _ys = [];
    private _zs = [];
    {
        private _xCoord = _x;
        {
            private _yCoord = _x;
            {
                private _point = (_entity modelToWorldWorld [_xCoord, _yCoord, _x]) vectorAdd _offset;
                _xs pushBack (_point select 0);
                _ys pushBack (_point select 1);
                _zs pushBack (_point select 2);
            } forEach [_min select 2, _max select 2];
        } forEach [_min select 1, _max select 1];
    } forEach [_min select 0, _max select 0];
    [selectMin _xs, selectMax _xs, selectMin _ys, selectMax _ys, selectMin _zs, selectMax _zs]
};
private _crateBounds = [_object, _delta] call _bounds;
if (_snapToGround) then {
    private _height = (_crateBounds select 5) - (_crateBounds select 4);
    private _ground = getTerrainHeightASL _position;
    _crateBounds set [4, _ground + 0.05];
    _crateBounds set [5, _ground + 0.05 + _height];
};
private _searchRadius = 50 max ((_object getVariable ["Radius", 1]) + 30);
// Only vehicles and actual players block placement. No scenery/ambient scans.
private _vehicles = nearestObjects [_position, ["LandVehicle", "Air", "Ship"], _searchRadius, true];
{
    if (isPlayer _x && {!(_x isKindOf "HeadlessClient_F")} && {_x distance2D _position <= _searchRadius}) then {
        _vehicles pushBackUnique _x;
    };
} forEach allPlayers;
private _blocked = _vehicles findIf {
    private _vehicleBounds = [_x, [0,0,0]] call _bounds;
    _x != _object && {_x != _carrier} && {!(_x in crew _object)} && {
        (_crateBounds select 0) < (_vehicleBounds select 1) + 0.5 &&
        {(_crateBounds select 1) > (_vehicleBounds select 0) - 0.5} &&
        {(_crateBounds select 2) < (_vehicleBounds select 3) + 0.5} &&
        {(_crateBounds select 3) > (_vehicleBounds select 2) - 0.5} &&
        {(_crateBounds select 4) < (_vehicleBounds select 5) - 0.05} &&
        {(_crateBounds select 5) > (_vehicleBounds select 4) + 0.05}
    }
};
if (_blocked >= 0) then {
    private _obstacle = _vehicles select _blocked;
    private _label = getText (configFile >> "CfgVehicles" >> typeOf _obstacle >> "displayName");
    if (_label == "") then {_label = typeOf _obstacle};
    if (_label == "") then {_label = str _obstacle};
    missionNamespace setVariable ["BW_PLACEMENT_BLOCKER", _label];
};
_blocked < 0
