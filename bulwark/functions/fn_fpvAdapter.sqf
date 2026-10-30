/* Server-only integration boundary for Ukraine FPV Drone, Workshop 3475006113.
   Does not spawn, assign targets or enable a special wave. */
params ["_operation", ["_drone", objNull]];
if (!isServer || {isRemoteExecuted}) exitWith {false};
private _class = "O_UAFPV_OG7V_AP";
if (_operation == "available") exitWith {
    isClass (configFile >> "CfgVehicles" >> _class) &&
    {!isNil "UA_fnc_fpv_onDestroy"} &&
    {_class in (missionNamespace getVariable ["UA_fpv_dronesArray", []])}
};
if (isNull _drone || {!local _drone} || {!(_drone getVariable ["bw_fpvOwned", false])}) exitWith {false};
switch (_operation) do {
    case "cleanup": {
        // Native destruction honours this flag. Delete directly, never kill it.
        _drone setVariable ["UA_FPV_PayloadSwapProtected", true, true];
        _drone setVariable ["bw_fpvTerminal", true, true];
        private _groups = [];
        {_groups pushBackUnique group _x; deleteVehicle _x} forEach crew _drone;
        deleteVehicle _drone;
        {if (units _x isEqualTo []) then {deleteGroup _x}} forEach _groups;
        true
    };
    case "detonate": {
        if (!alive _drone || {_drone getVariable ["bw_fpvTerminal", false]} ||
            {_drone getVariable ["UA_FPV_Detonated", false]} ||
            {_drone getVariable ["UA_FPV_PayloadSwapProtected", false]} ||
            {_drone getVariable ["UA_FPV_PayloadSpawnSettling", false]} ||
            {isNil "UA_fnc_fpv_onDestroy"}) exitWith {false};
        private _done = false;
        isNil {
            if !(_drone getVariable ["bw_fpvTerminal", false]) then {
                _drone setVariable ["bw_fpvTerminal", true, true];
                [_drone, objNull, 1, objNull] call UA_fnc_fpv_onDestroy;
                _done = isNull _drone || {_drone getVariable ["UA_FPV_Detonated", false]};
                if (!_done) then {_drone setVariable ["bw_fpvTerminal", false, true]};
            };
        };
        _done
    };
    default {false};
}
