if (!isServer) exitWith {};
params [["_wave", attkWave]];
private _classes = "getNumber (_x >> 'scope') == 2 && {getNumber (_x >> 'side') == 3} && {getNumber (_x >> 'isMan') == 1}" configClasses (configFile >> "CfgVehicles");
_classes = _classes apply {configName _x};
private _houses = [];
{
    {_houses pushBackUnique _x} forEach (nearestObjects [_x, ["House"], BULWARK_RADIUS]);
} forEach (([] call bulwark_fnc_humanPlayers) select {alive _x});
private _positions = [];
{_positions append (_x buildingPos -1)} forEach _houses;
if (_classes isEqualTo [] || {_positions isEqualTo []}) exitWith {
    diag_log "Bulwark: civilian special skipped; no valid classes or building positions";
};
private _civilians = [];
private _groups = [];
for "_i" from 1 to 20 do {
    if !([_wave] call bulwark_fnc_waveActive) exitWith {};
    private _group = createGroup [civilian, true];
    private _unit = _group createUnit [selectRandom _classes, selectRandom _positions, [], 0, "NONE"];
    if (!isNull _unit) then {
        _groups pushBack _group;
        _civilians pushBack _unit;
        _unit addEventHandler ["Killed", killPoints_fnc_civKilled];
        _unit allowFleeing 0;
        _unit setBehaviour "CARELESS";
        [_group, getPosATL _unit, 50] call lambs_wp_fnc_taskPatrol;
    } else {deleteGroup _group};
};
if (!isNil "mainZeus") then {mainZeus addCuratorEditableObjects [_civilians, true]};
waitUntil {sleep 0.5; !([_wave] call bulwark_fnc_waveActive)};
{deleteVehicle _x} forEach _civilians;
{deleteGroup _x} forEach _groups;
