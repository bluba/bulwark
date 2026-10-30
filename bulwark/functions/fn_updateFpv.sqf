if (!isServer || {isRemoteExecuted}) exitWith {};
private _r = missionNamespace getVariable ["BW_FPV_OPERATOR",createHashMap];
if (count _r == 0) exitWith {};
private _reason = "";
if (!([_r get "wave"] call bulwark_fnc_waveActive)) then {_reason = "cancelled"} else {
    if ((_r get "state") != "closing") then {
        if (scriptDone (_r getOrDefault ["worker",scriptNull])) then {_reason = "workerFailed"};
        if ((_r get "state") == "setup" && {time >= (_r get "setupDeadline")}) then {_reason = "setupTimeout"};
        if ((_r get "state") == "active") then {
            if (!alive (_r get "operator") || {!alive (_r get "device")}) then {_reason = "destroyed"};
            if (time >= (_r get "deadline")) then {_reason = "expired"};
            if ((_r get "device") distance2D (_r get "position") > 5 || {!isNull attachedTo (_r get "device")}) then {_reason = "relocated"};
            if (isNull (_r get "anchor") || {!((_r get "anchor") isEqualTo bulwarkBox)} ||
                {bulwarkBox distance2D (_r get "origin") >= 150}) then {_reason = "relocated"};
            if ((_r get "starts") >= ((_r get "settings") get "START_LIMIT") && {(_r get "drones") isEqualTo []}) then {_reason = "exhausted"};
        };
    };
};
if (_reason != "") then {[_r get "id",_reason] call bulwark_fnc_endFpv};
if ((_r get "state") == "active") then {
    private _group = _r get "group";
    if (!isNull _group) then {[_group,_r get "wave",_r get "id"] remoteExecCall ["bulwark_fnc_controlFpvPost",groupOwner _group]};
};
if ((_r get "state") == "closing" && {scriptDone (_r getOrDefault ["worker",scriptNull])}) then {BW_FPV_OPERATOR = createHashMap};
