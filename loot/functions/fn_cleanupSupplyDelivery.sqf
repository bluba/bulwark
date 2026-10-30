// Called only with an owned family record, before terminating its worker.
params ["_record", ["_includeSmoke", false]];
if (!isServer || {isRemoteExecuted}) exitWith {};
private _crate = _record getOrDefault ["crate", objNull];
if (!isNull _crate) then {detach _crate};
{
    private _object = _record getOrDefault [_x, objNull];
    if (!isNull _object) then {deleteVehicle _object};
    _record set [_x, objNull];
} forEach (if (_includeSmoke) then {["parachute", "aircraft", "smoke"]} else {["parachute", "aircraft"]});
{if (!isNull _x) then {deleteVehicle _x}} forEach (_record getOrDefault ["crew", []]);
private _group = _record getOrDefault ["group", grpNull];
if (!isNull _group) then {deleteGroup _group};
_record set ["crew", []];
_record set ["group", grpNull];
