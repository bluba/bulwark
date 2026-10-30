// The wave owner calls this once after ordinary loot refresh. Reserve before spawn.
params ["_wave", ["_family", "medical"]];
if (!isServer || {isRemoteExecuted}) exitWith {false};
private _keys = [_family] call loot_fnc_supplyFamily;
if (_keys isEqualTo []) exitWith {false};
_keys params ["_recordKey", "_attemptKey", "_resultKey", "_statusKey", "_enabledKey", "_chanceKey", "_classKey"];
private _started = false;
isNil {
    private _chance = missionNamespace getVariable [_chanceKey, 0.20];
    private _record = missionNamespace getVariable [_recordKey, createHashMap];
    if ((missionNamespace getVariable [_enabledKey, true]) &&
        {_chance isEqualType 0 && {finite _chance} && {_chance >= 0} && {_chance <= 1}} &&
        {[_wave] call bulwark_fnc_waveActive} && {_wave >= 1} &&
        {_wave != (missionNamespace getVariable [_attemptKey, -1])} &&
        {count _record == 0} && {!isNil "bulwarkBox"} && {!isNull bulwarkBox}) then {
        missionNamespace setVariable [_attemptKey, _wave];
        // Consume misses too: repeated calls must not reroll the same wave.
        if (random 1 < _chance) then {
            BW_SUPPLY_SERIAL = (missionNamespace getVariable ["BW_SUPPLY_SERIAL", 0]) + 1;
            private _id = BW_SUPPLY_SERIAL;
            private _newRecord = createHashMapFromArray [
                ["id", _id], ["family", _family], ["wave", _wave], ["state", "placing"], ["crate", objNull],
                ["anchorObject", bulwarkBox], ["anchorPosition", getPosATL bulwarkBox]
            ];
            missionNamespace setVariable [_recordKey, _newRecord];
            private _worker = [_id, _family] spawn loot_fnc_watchSupplyCache;
            _newRecord set ["worker", _worker];
            _started = true;
        };
    };
};
_started
