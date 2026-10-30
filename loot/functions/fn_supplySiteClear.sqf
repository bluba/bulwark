// Return a supported ATL position, or []. This is geometry screening, not pathfinding.
params ["_pos", "_anchor", "_min", "_max", ["_indoor", false], ["_ignore1", objNull], ["_ignore2", objNull]];
if (count _pos != 3 || {(_pos findIf {!(_x isEqualType 0) || {!finite _x}}) >= 0}) exitWith {[]};
if ((_pos select 0) <= 1 || {(_pos select 1) <= 1} || {(_pos select 0) >= worldSize - 1} ||
    {(_pos select 1) >= worldSize - 1} || {surfaceIsWater _pos} ||
    {_pos distance2D _anchor < _min} || {_pos distance2D _anchor > _max} ||
    {(_pos select 2) < -0.1} || {(_pos select 2) > 1.8}) exitWith {[]};
if (!_indoor && {isOnRoad _pos || {
    !(nearestTerrainObjects [_pos, ["TREE", "SMALL TREE", "BUSH", "ROCK", "ROCKS", "HIDE"], 1.5, false] isEqualTo [])
}}) exitWith {[]};
private _asl = ATLToASL _pos;
private _support = lineIntersectsSurfaces [_asl vectorAdd [0,0,0.35], _asl vectorAdd [0,0,-0.8],
    _ignore1, _ignore2, true, 1, "GEOM", "FIRE"];
if (_support isEqualTo [] || {((_support select 0 select 1) select 2) < 0.94}) exitWith {[]};
private _base = (_support select 0 select 0) vectorAdd [0,0,0.05];
private _clear = !lineIntersects [_base vectorAdd [0,0,0.1], _base vectorAdd [0,0,1.5], _ignore1, _ignore2];
private _approach = false;
{
    private _offset = [sin _x, cos _x, 0];
    if (lineIntersects [_base vectorAdd [0,0,0.45], (_base vectorAdd [0,0,0.45]) vectorAdd (_offset vectorMultiply 1), _ignore1, _ignore2]) then {_clear = false};
    private _from = _base vectorAdd [0,0,0.8];
    private _to = _from vectorAdd (_offset vectorMultiply 3);
    if (!lineIntersects [_from, _to, _ignore1, _ignore2] && {!terrainIntersectASL [_from, _to]}) then {_approach = true};
} forEach [0,45,90,135,180,225,270,315];
if (!_clear || {!_approach}) exitWith {[]};
ASLToATL _base
