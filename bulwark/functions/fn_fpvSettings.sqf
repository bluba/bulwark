// Reject malformed configuration rather than silently defeating hard limits.
private _s = createHashMap;
private _ok = true;
{
    _x params ["_key", "_default", "_min", "_max"];
    private _v = missionNamespace getVariable ["BW_FPV_" + _key, _default];
    if (!(_v isEqualType 0) || {!finite _v} || {_v < _min} || {_v > _max} || {_v != floor _v}) exitWith {_ok = false};
    _s set [_key, _v];
} forEach [["MIN_WAVE",10,1,9999],["COOLDOWN",2,0,20],["GUARDS",2,2,3],
    ["CAP",2,1,2],["START_LIMIT",10,1,20],["LIFETIME",480,60,600],
    ["DRONE_LIFETIME",90,15,120],["FIRST_DELAY",30,15,90],["INTERVAL_MIN",35,15,120],
    ["INTERVAL_MAX",50,15,150],["TARGET_COOLDOWN",20,5,60],["SETUP_TIMEOUT",30,5,60]];
if (!_ok || {(_s get "INTERVAL_MAX") < (_s get "INTERVAL_MIN")}) exitWith {createHashMap};
_s
