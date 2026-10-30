params ["_id", ["_reason", "cancelled"]];
if (!isServer || {isRemoteExecuted} || {_id < 0}) exitWith {false};
private _ended = false;
isNil {
    private _record = missionNamespace getVariable ["BW_OFFICER_HUNT", createHashMap];
    if ((_record getOrDefault ["id", -1]) == _id && {(_record get "state") != "closing"}) then {
        _record set ["state", "closing"];
        _record set ["reason", _reason];
        BW_OFFICER_RESULT = [_id, _reason, serverTime];
        missionNamespace setVariable ["BW_OFFICER_STATUS", [], true];
        private _wave = _record get "wave";
        private _assault = [_wave] call bulwark_fnc_waveActive;
        private _groups = [_record getOrDefault ["postGroup", grpNull]] select {!isNull _x};
        {
            if (!isNull _x && {(_x getVariable ["bw_officerId", -1]) == _id}) then {
                _groups pushBackUnique (group _x);
                _x setVariable ["bw_stationary", false, true];
                _x setVariable ["aiMode", "rush", true];
                if (!_assault) then {[_x, _id] remoteExecCall ["bulwark_fnc_removeOfficerUnit", owner _x]};
            };
        } forEach (_record get "units");
        {
            if ((_x getVariable ["bw_officerId", -1]) == _id) then {
                _x setVariable ["bw_officerActive", false, true];
                _x setVariable ["bw_scriptedMovement", false, true];
                _x setVariable ["bw_baseMode", "rush", true];
                [_x, _wave, _id, _record getOrDefault ["position", [0,0,0]], true] remoteExecCall ["bulwark_fnc_controlOfficerPost", groupOwner _x];
            };
            if (units _x isEqualTo []) then {deleteGroup _x};
        } forEach _groups;
        if (_reason in ["killed", "expired"] && {_assault}) then {
            [_reason] remoteExecCall ["bulwark_fnc_officerNotice", 0];
        };
        _ended = true;
    };
};
_ended
