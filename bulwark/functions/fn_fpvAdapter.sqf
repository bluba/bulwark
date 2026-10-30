/* Server-only integration boundary for Ukraine FPV Drone, Workshop 3475006113. */
params ["_operation", ["_drone", objNull]];
if (!isServer || {isRemoteExecuted}) exitWith {false};
private _class = "O_UAFPV_OG7V_AP";
if (_operation == "available") exitWith {
    isClass (configFile >> "CfgVehicles" >> _class) &&
    {isClass (configFile >> "CfgVehicles" >> "I_UAFPV_OG7V_AP")} &&
    {isClass (configFile >> "CfgAmmo" >> "R_TBG32V_F")} &&
    {!isNil "UA_fnc_fpv_onDestroy"} &&
    {!isNil "UA_fnc_fpv_getPayloadType"} &&
    {_class in (missionNamespace getVariable ["UA_fpv_dronesArray", []])}
};
if (isNull _drone || {!(_drone getVariable ["bw_fpvOwned", false])}) exitWith {false};
switch (_operation) do {
    case "prepare": {
        if (!local _drone || {_drone getVariable ["bw_fpvPrepared",false]} ||
            {!(typeOf _drone in ["O_UAFPV_OG7V_AP","I_UAFPV_OG7V_AP"])}) exitWith {false};
        _drone setVariable ["bw_fpvPrepared",true];
        _drone setVariable ["UA_FPV_DroneInitStarted",true];
        _drone setVariable ["UA_FPV_TakeoffProtectionGeneration",1 + (_drone getVariable ["UA_FPV_TakeoffProtectionGeneration",0]),true];
        _drone setVariable ["UA_FPV_TakeoffProtectionActive",false,true];
        _drone setVariable ["UA_FPV_PayloadSpawnSettling",false,true];
        _drone setVariable ["UA_FPV_PayloadSwapProtected",true,true];
        _drone setVariable ["UA_FPV_PayloadType","OG7V",true];
        _drone setVariable ["DB_jammer_customUavBehavior",true,true];
        _drone allowDamage true;
        _drone setVehicleLock "LOCKEDPLAYER";
        _drone engineOn true;
        _drone addEventHandler ["Hit", {if ((_this param [2,0]) > 0) then {(_this select 0) setVariable ["bw_fpvShotDown",true]}}];
        true
    };
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
        if (!local _drone || {!alive _drone} || {_drone getVariable ["bw_fpvTerminal", false]} ||
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
