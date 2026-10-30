params ["_p", "_anchor", ["_ignore",objNull]];
if (!(_p isEqualType []) || {count _p != 3} || {(_p findIf {!(_x isEqualType 0) || {!finite _x}}) >= 0}) exitWith {false};
if ((_p select 0) < 10 || {(_p select 1) < 10} || {(_p select 0) > worldSize - 10} ||
    {(_p select 1) > worldSize - 10} || {_p distance2D _anchor < 300} || {_p distance2D _anchor > 700} ||
    {surfaceIsWater _p} || {(surfaceNormal _p select 2) < 0.97} || {isOnRoad _p}) exitWith {false};
if (!(nearestObjects [_p,["House","LandVehicle","StaticWeapon"],8] isEqualTo []) ||
    {!(nearestTerrainObjects [_p,["TREE","SMALL TREE","ROCK","ROCKS"],6,false] isEqualTo [])}) exitWith {false};
private _floor = ATLToASL _p;
if (lineIntersects [_floor vectorAdd [0,0,0.3], _floor vectorAdd [0,0,18],_ignore,objNull]) exitWith {false};
private _blocked = [0,90,180,270] findIf {
    private _end = _p getPos [8,_x];
    surfaceIsWater _end || {abs ((getTerrainHeightASL _end) - (getTerrainHeightASL _p)) > 1.5} ||
    {lineIntersects [_floor vectorAdd [0,0,1], (ATLToASL _end) vectorAdd [0,0,1],_ignore,objNull]}
};
if (_blocked >= 0) exitWith {false};
private _players = ([] call bulwark_fnc_humanPlayers) select {alive _x};
(_players findIf {
    private _eye = eyePos _x;
    private _observer = _x;
    _x distance2D _p < 200 || {
        [1.5,4] findIf {
            private _point = _floor vectorAdd [0,0,_x];
            !terrainIntersectASL [_eye,_point] && {!lineIntersects [_eye,_point,_observer,_ignore]}
        } >= 0
    }
}) < 0
