// Prefer the selected support target; preserve full marker-owner IDs as a fallback.
params ["_player", ["_target", []]];
if (_target isEqualType [] && {count _target >= 2}) exitWith {+_target};
private _ownerId = if (isMultiplayer) then {str (owner _player)} else {"0"};
private _result = [];
{
    if (_x find "_USER_DEFINED #" == 0) then {
        private _parts = (_x select [15]) splitString "/";
        if (count _parts > 0 && {(_parts select 0) == _ownerId}) then {_result = getMarkerPos _x};
    };
} forEach allMapMarkers;
_result
