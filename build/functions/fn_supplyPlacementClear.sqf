// Shared build placement guard. Compare horizontal world bounding boxes with a margin.
// Ignoring height also protects against ground snap lowering a crate into a vehicle.
params ["_object", "_position"];
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
    {
        private _xCoord = _x;
        {
            private _yCoord = _x;
            {
                private _point = (_entity modelToWorldWorld [_xCoord, _yCoord, _x]) vectorAdd _offset;
                _xs pushBack (_point select 0);
                _ys pushBack (_point select 1);
            } forEach [_min select 2, _max select 2];
        } forEach [_min select 1, _max select 1];
    } forEach [_min select 0, _max select 0];
    [selectMin _xs, selectMax _xs, selectMin _ys, selectMax _ys]
};
private _crateBounds = [_object, _delta] call _bounds;
private _searchRadius = 50 max ((_object getVariable ["Radius", 1]) + 30);
// Construction may intersect scenery and other construction (sandbag stacking).
// Vehicles, characters and supply crates still need full geometry clearance.
private _fullClearance = (_object isKindOf "LandVehicle") ||
    {_object isKindOf "Air"} || {_object isKindOf "Ship"} ||
    {_object isKindOf "Man"} || {_object isKindOf "ReammoBox_F"} ||
    {(_object getVariable ["bw_supplyPurchase", ""]) != ""};
private _types = ["LandVehicle", "Air", "Ship", "Man"];
if (_fullClearance) then {_types append ["Thing", "House"]};
private _vehicles = nearestObjects [_position, _types, _searchRadius, true];
if (_fullClearance) then {
    {_vehicles pushBackUnique _x} forEach (nearestTerrainObjects [_position, ["TREE", "SMALL TREE", "ROCK", "ROCKS", "WALL", "FENCE", "HOUSE", "BUILDING"], _searchRadius, false, true]);
};
private _bulwark = missionNamespace getVariable ["bulwarkBox", objNull];
if (!isNull _bulwark) then {_vehicles pushBackUnique _bulwark};
private _blocked = _vehicles findIf {
    private _vehicleBounds = [_x, [0,0,0]] call _bounds;
    _x != _object && {_x != _carrier} && {!(_x in crew _object)} && {
        (_crateBounds select 0) < (_vehicleBounds select 1) + 0.5 &&
        {(_crateBounds select 1) > (_vehicleBounds select 0) - 0.5} &&
        {(_crateBounds select 2) < (_vehicleBounds select 3) + 0.5} &&
        {(_crateBounds select 3) > (_vehicleBounds select 2) - 0.5}
    }
};
_blocked < 0
