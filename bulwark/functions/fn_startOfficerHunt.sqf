params ["_wave"];
if (!isServer || {isRemoteExecuted} || {!([_wave] call bulwark_fnc_waveActive)}) exitWith {false};
private _settings = [] call bulwark_fnc_officerSettings;
if (count _settings == 0) exitWith {false};
private _defector = missionNamespace getVariable ["defectorWave", false];
private _side = if (_defector) then {resistance} else {east};
private _classes = missionNamespace getVariable [if (_defector) then {"DEFECTOR_INF"} else {"HOSTILE_LEVEL_2"}, []];
private _higher = if (_defector) then {[]} else {missionNamespace getVariable ["HOSTILE_LEVEL_3", []]};
if (!(_classes isEqualType []) || {!(_higher isEqualType [])}) exitWith {false};
_classes = _classes + _higher;
private _officers = missionNamespace getVariable [if (_defector) then {"BW_OFFICER_DEFECTOR_CLASSES"} else {"BW_OFFICER_CLASSES"}, []];
if (!(_classes isEqualType []) || {!(_officers isEqualType [])}) exitWith {false};
private _validClasses = {params ["_pool"]; _pool select {_x isEqualType "" && {isClass (configFile >> "CfgVehicles" >> _x)} && {_x isKindOf ["Man", configFile >> "CfgVehicles"]}}};
_classes = [_classes] call _validClasses;
_officers = [_officers] call _validClasses;
if (_classes isEqualTo []) exitWith {diag_log "Bulwark Officer Hunt: no valid infantry"; false};
if (_officers isEqualTo []) then {_officers = [_classes select 0]};
private _started = false;
isNil {
    if (([_wave] call bulwark_fnc_waveActive) && {[_wave] call bulwark_fnc_officerHuntAvailable}) then {
        BW_OFFICER_SERIAL = (missionNamespace getVariable ["BW_OFFICER_SERIAL", 0]) + 1;
        private _id = BW_OFFICER_SERIAL;
        BW_OFFICER_HUNT = createHashMapFromArray [["id",_id],["wave",_wave],["state","settingUp"],
            ["settings",_settings],["side",_side],["classes",_classes],["officerClass",_officers select 0],
            ["units",[]],["reinforcementGroups",[]],["postGroup",grpNull],["officer",objNull],["pendingJob",scriptNull]];
        private _worker = [[_id], "hostiles\officerHunt.sqf"] call bulwark_fnc_queueHostiles;
        BW_OFFICER_HUNT set ["worker", _worker];
        _started = true;
    };
};
_started
