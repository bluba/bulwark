// Validate once per selection/setup. No client-supplied profile or new dependency.
private _settings = createHashMap;
private _valid = true;
{
    _x params ["_key", "_default", "_min", "_max"];
    private _value = missionNamespace getVariable ["BW_OFFICER_" + _key, _default];
    if (!(_value isEqualType 0) || {!finite _value} || {_value != floor _value} || {_value < _min} || {_value > _max}) exitWith {_valid = false};
    _settings set [_key, _value];
} forEach [["MIN_WAVE",10,10,9999], ["COOLDOWN_WAVES",2,0,20], ["GUARDS",4,0,4],
    ["TEAM_SIZE",4,1,4], ["TEAM_CAP",2,1,2], ["INTERVAL",90,30,300],
    ["TIMEOUT",60,5,60], ["LIFETIME",600,60,600]];
if (!_valid) exitWith {createHashMap};
_settings
