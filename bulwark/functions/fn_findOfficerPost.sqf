params ["_anchor"];
private _min = 300 max (BULWARK_RADIUS + 100);
private _players = ([] call bulwark_fnc_humanPlayers) select {alive _x};
private _result = [];
for "_attempt" from 1 to 16 do {
    private _pos = _anchor getPos [_min + random 200, random 360];
    _pos set [2,0];
    if ((_pos select 0) > 10 && {(_pos select 1) > 10} &&
        {(_pos select 0) < worldSize - 10} && {(_pos select 1) < worldSize - 10} &&
        {!surfaceIsWater _pos} && {(surfaceNormal _pos select 2) >= 0.95} &&
        {(_players findIf {_x distance2D _pos < 200}) < 0} &&
        {isNil "bulwarkBox" || {isNull bulwarkBox} || {bulwarkBox distance2D _pos >= 200}} &&
        {nearestObjects [_pos, ["House", "LandVehicle", "StaticWeapon"], 12] isEqualTo []} &&
        {nearestTerrainObjects [_pos, ["TREE","SMALL TREE","ROCK","ROCKS"], 8, false] isEqualTo []} &&
        {!lineIntersects [ATLToASL (_pos vectorAdd [0,0,0.2]), ATLToASL (_pos vectorAdd [0,0,2])]} &&
        {([0,90,180,270] findIf {
            private _end = _pos getPos [6,_x];
            lineIntersects [ATLToASL (_pos vectorAdd [0,0,1]), ATLToASL (_end vectorAdd [0,0,1])]
        }) < 0}) exitWith {_result = _pos};
};
_result
