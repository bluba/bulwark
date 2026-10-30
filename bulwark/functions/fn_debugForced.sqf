// Server-only, exact wave/type exception; never changes persistent lobby settings.
params ["_wave", ["_type", ""]];
private _forced = missionNamespace getVariable ["BW_DEBUG_FORCED_WAVE", []];
isServer && {count _forced == 2} && {(_forced select 0) == _wave} &&
{_type == "" || {_type == (_forced select 1)}}
