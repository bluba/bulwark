// Register autonomous friendly reinforcements; dispatch orders to their current owner.
params ["_group", "_asset", ["_buyer", objNull]];
if (!isServer || {isNull _group} || {isNull _asset}) exitWith {};
// Calls from authenticated purchase/support handlers retain their remote context.
if (isRemoteExecuted && {remoteExecutedOwner != 2} && {
    !([_buyer] call bulwark_fnc_validCaller) ||
    {_asset getVariable ["bw_purchaseOwner", ""] != getPlayerUID _buyer} ||
    {(_asset getVariable ["bw_allyGroup", grpNull]) != _group}
}) exitWith {};
_group setVariable ["bw_allyAsset", _asset, true];
_group setVariable ["bw_allyType", if (_asset isKindOf "Man") then {"infantry"} else {
    if (_asset isKindOf "StaticWeapon") then {"static"} else {"vehicle"}
}, true];
if (isNil {_group getVariable "bw_allyDuty"}) then {
    _group setVariable ["bw_allyDuty", selectRandom ["patrol", "camp"], true];
};
_group setVariable ["bw_allyManaged", true, true];
private _job = _group getVariable ["bw_allyServerJob", scriptNull];
if (!scriptDone _job) exitWith {};
_job = [_group] spawn {
    params ["_group"];
    while {!isNull _group && {_group getVariable ["bw_allyManaged", false]} &&
        {(units _group findIf {alive _x}) >= 0} && {missionNamespace getVariable ["runMissionLoop", true]}} do {
        private _asset = _group getVariable ["bw_allyAsset", objNull];
        if ((_group getVariable ["bw_allyType", ""]) != "infantry" && {!alive _asset}) exitWith {};
        private _truck = missionNamespace getVariable ["bulwarkBox", objNull];
        if (!isNull _truck && {alive _truck}) then {
            // Queue even server-local execution with server origin, independent
            // of the purchase/support caller's original remote-execution context.
            [_group, _asset, _truck] remoteExecCall ["bulwark_fnc_controlAllyGroup", groupOwner _group];
        };
        sleep 2;
    };
    if (!isNull _group) then {_group setVariable ["bw_allyManaged", false, true]};
};
_group setVariable ["bw_allyServerJob", _job];
