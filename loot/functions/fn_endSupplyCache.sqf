// Instance-bound and idempotent. All mutations finish before terminating the worker.
params ["_id", ["_reason", "cancelled"], ["_family", "medical"]];
if (!isServer || {isRemoteExecuted}) exitWith {false};
private _keys = [_family] call loot_fnc_supplyFamily;
if (_keys isEqualTo []) exitWith {false};
_keys params ["_recordKey", "_attemptKey", "_resultKey", "_statusKey"];
private _ended = false;
isNil {
    private _record = missionNamespace getVariable [_recordKey, createHashMap];
    if ((_record getOrDefault ["id", -1]) == _id && {_id >= 0}) then {
        _record set ["state", "terminal"];
        missionNamespace setVariable [_statusKey, [], true];
        missionNamespace setVariable [_keys select 7, [], true];
        [_record, true] call loot_fnc_cleanupSupplyDelivery;
        private _crate = _record getOrDefault ["crate", objNull];
        if (!isNull _crate) then {deleteVehicle _crate};
        private _worker = _record getOrDefault ["worker", scriptNull];
        missionNamespace setVariable [_recordKey, createHashMap];
        missionNamespace setVariable [_resultKey, [_id, _reason, serverTime]];
        diag_log format ["Bulwark %1 supply %2: %3", _family, _id, _reason];
        _ended = true;
        if (!scriptDone _worker) then {terminate _worker};
    };
};
_ended
