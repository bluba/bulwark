params ["_wave"];
if (!isServer || {isRemoteExecuted} || {!([_wave] call bulwark_fnc_waveActive)}) exitWith {false};
if (isNil "bulwarkBox" || {isNull bulwarkBox}) exitWith {false};
private _started = false;
isNil {
    if ([_wave] call bulwark_fnc_fpvAvailable) then {
        BW_FPV_SERIAL = (missionNamespace getVariable ["BW_FPV_SERIAL",0]) + 1;
        private _id = BW_FPV_SERIAL;
        BW_FPV_OPERATOR = createHashMapFromArray [["id",_id],["wave",_wave],["state","setup"],
            ["settings",[] call bulwark_fnc_fpvSettings],["anchor",bulwarkBox],["origin",getPosATL bulwarkBox],
            ["units",[]],["group",grpNull],["device",objNull],["operator",objNull],["drones",[]],
            ["history",createHashMap],["starts",0],["setupDeadline",time + 60]];
        BW_FPV_OPERATOR set ["worker", [[_id],"hostiles\fpvOperator.sqf"] call bulwark_fnc_queueHostiles];
        _started = true;
    };
};
_started
