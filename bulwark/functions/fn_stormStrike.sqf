// Effects run on viewers; the server-local target gives the native module one
// damage authority. Never pass a player, vehicle or curator-editable object.
params ["_target", "_wave", "_sentAt"];
if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
if (!canSuspend || {!hasInterface && {!isServer}} || {isNull _target} ||
    {typeOf _target != "Land_HelipadEmpty_F"} || {!(_target getVariable ["bw_stormTarget", false])} ||
    {serverTime - _sentAt > 5} || {missionNamespace getVariable ["buildPhase", true]} ||
    {_wave != (missionNamespace getVariable ["attkWave", -1])}) exitWith {};
private _state = missionNamespace getVariable ["BW_STORM_STATE", [0, false, 0]];
if (!(_state select 1) || {_wave != (_state select 0)}) exitWith {};
if (isServer && {!([_wave] call bulwark_fnc_waveActive) || {!local _target}}) exitWith {};
// Local-only deduplication: each viewer renders once; the server damages once.
private _accepted = false;
isNil {
    if !(_target getVariable ["bw_stormRendered", false]) then {
        _target setVariable ["bw_stormRendered", true];
        _accepted = true;
    };
};
if (!_accepted) exitWith {};
[_target, nil, true] call BIS_fnc_moduleLightning;
