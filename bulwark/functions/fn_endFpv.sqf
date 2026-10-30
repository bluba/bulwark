params ["_id",["_reason","cancelled"]];
if (!isServer || {isRemoteExecuted}) exitWith {false};
private _ended = false;
isNil {
    private _r = missionNamespace getVariable ["BW_FPV_OPERATOR",createHashMap];
    if (_id >= 0 && {(_r getOrDefault ["id",-1]) == _id}) then {
        private _first = (_r get "state") != "closing";
        _r set ["state","closing"];
        // Repeat calls can escalate combat handoff to full mission cancellation.
        private _assault = [_r get "wave"] call bulwark_fnc_waveActive;
        { ["cleanup",_x get "object"] call bulwark_fnc_fpvAdapter } forEach (_r get "drones");
        _r set ["drones",[]];
        deleteVehicle (_r get "device");
        private _group = _r get "group";
        _group setVariable ["bw_fpvActive",false,true];
        _group setVariable ["bw_scriptedMovement",false,true];
        _group setVariable ["bw_baseMode","rush",true];
        {
            _x setVariable ["bw_stationary",false,true];
            _x setVariable ["aiMode","rush",true];
            if (!_assault) then {deleteVehicle _x};
        } forEach (_r get "units");
        if (!isNull _group) then {
            if (_assault) then {[_group,_r get "wave",_id,true] remoteExecCall ["bulwark_fnc_controlFpvPost",groupOwner _group]} else {deleteGroup _group};
        };
        missionNamespace setVariable ["BW_FPV_STATUS",[],true];
        if (_first) then {
            BW_FPV_RESULT = [_id,_reason,serverTime];
            if (_assault && {_reason in ["destroyed","expired","exhausted","relocated"]}) then {["ended"] remoteExecCall ["bulwark_fnc_fpvNotice",0]};
            diag_log format ["Bulwark FPV %1 ended: %2",_id,_reason];
        };
        _ended = true;
    };
};
_ended
