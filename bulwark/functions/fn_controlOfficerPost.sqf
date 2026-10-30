// Handles and lease are local to this owner, including after HC migration.
params ["_group", "_wave", "_id", "_position", ["_release", false]];
if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
if (isNull _group || {!local _group} || {(_group getVariable ["bw_officerId", -1]) != _id}) exitWith {};
private _allowed = {
    (units _group findIf {isPlayer _x || {!isNull (remoteControlled _x)} ||
        {!isNull (_x getVariable ["BIS_fnc_moduleRemoteControl_owner", objNull])} ||
        {(_x getVariable ["bw_officerId", -1]) != _id}}) < 0
};
if (_release || {!(call _allowed)}) exitWith {
    {private _h = _group getVariable [_x, scriptNull]; if (!scriptDone _h) then {terminate _h}} forEach ["bw_officerTask", "bw_officerWatch"];
    _group setVariable ["bw_officerMachine", -1];
    if (_release && {call _allowed}) then {
        [_group, true, true] call lambs_wp_fnc_taskReset;
        [_group, _wave] call bulwark_fnc_controlEnemyGroup;
    };
};
if (!(_group getVariable ["bw_officerActive", false]) ||
    {missionNamespace getVariable ["buildPhase", true]} || {_wave != (missionNamespace getVariable ["attkWave", -1])}) exitWith {};
_group setVariable ["bw_officerLease", diag_tickTime + 10];
if ((_group getVariable ["bw_officerMachine", -1]) == clientOwner) exitWith {};
_group setVariable ["bw_officerMachine", clientOwner];
// Initial creation can have been observed by the generic five-second dispatcher.
{private _h = _group getVariable [_x, scriptNull]; if (!scriptDone _h) then {terminate _h}} forEach ["bw_taskHandle", "bw_taskWatch"];
[_group, true, true] call lambs_wp_fnc_taskReset;
_group setVariable ["bw_aiMode", ""];
private _task = [_group, _position, 50] spawn lambs_wp_fnc_taskPatrol;
_group setVariable ["bw_officerTask", _task];
private _watch = [_group, _task, _wave, _id] spawn {
    params ["_group", "_task", "_wave", "_id"];
    waitUntil {
        sleep 0.5;
        !local _group || {isNull _group} || {!(_group getVariable ["bw_officerActive", false])} ||
        {diag_tickTime > (_group getVariable ["bw_officerLease", 0])} ||
        {missionNamespace getVariable ["buildPhase", true]} || {_wave != (missionNamespace getVariable ["attkWave", -1])} ||
        {(units _group findIf {isPlayer _x || {!isNull (remoteControlled _x)} ||
            {!isNull (_x getVariable ["BIS_fnc_moduleRemoteControl_owner", objNull])} ||
            {(_x getVariable ["bw_officerId", -1]) != _id}}) >= 0}
    };
    if (!scriptDone _task) then {terminate _task};
    if (local _group) then {
        _group setVariable ["bw_officerMachine", -1];
        if ((units _group findIf {isPlayer _x || {!isNull (remoteControlled _x)} ||
            {!isNull (_x getVariable ["BIS_fnc_moduleRemoteControl_owner", objNull])} ||
            {(_x getVariable ["bw_officerId", -1]) != _id}}) < 0) then {
            [_group, true, true] call lambs_wp_fnc_taskReset;
        };
    };
};
_group setVariable ["bw_officerWatch", _watch];
