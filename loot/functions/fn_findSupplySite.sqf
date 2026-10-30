// Open landing zones only: at most 24 preferred + 12 fallback candidates.
params ["_anchor", ["_exclusions", []]];
private _result = [];
{
    _x params ["_min", "_max", "_budget"];
    for "_i" from 1 to _budget do {
        private _direction = random 360;
        private _distance = _min + random (_max - _min);
        private _pos = [(_anchor select 0) + sin _direction * _distance, (_anchor select 1) + cos _direction * _distance, 0];
        if ((_exclusions findIf {_pos distance2D _x < 20}) < 0) then {
            private _candidate = [_pos, _anchor, _min, _max] call loot_fnc_supplySiteClear;
            if !(_candidate isEqualTo []) then {
                private _asl = ATLToASL _candidate;
                if (!lineIntersects [_asl vectorAdd [0,0,0.5], _asl vectorAdd [0,0,300]]) then {_result = _candidate};
            };
        };
        if !(_result isEqualTo []) exitWith {};
    };
    if !(_result isEqualTo []) exitWith {};
} forEach [[150,300,24], [100,150,12]];
_result
