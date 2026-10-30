// Existing phase tick and producer share this non-suspending, instance-bound monitor.
if (!isServer || {isRemoteExecuted}) exitWith {};
isNil {
    private _r = missionNamespace getVariable ["BW_OFFICER_HUNT", createHashMap];
    if (count _r > 0) then {
        private _id = _r get "id";
        private _wave = _r get "wave";
        private _state = _r get "state";
        if (_state != "closing") then {
            private _reason = "";
            if (!([_wave] call bulwark_fnc_waveActive)) then {_reason = "cancelled"} else {
                if (scriptDone (_r getOrDefault ["worker", scriptNull])) then {_reason = "workerFailed"} else {
                    if (_state == "active") then {
                        private _officer = _r get "officer";
                        _reason = if (isNull _officer) then {"deleted"} else {
                            if (!alive _officer) then {"killed"} else {if (time >= (_r get "deadline")) then {"expired"} else {""}}
                        };
                    };
                };
            };
            if (_reason != "") then {
                [_id, _reason] call bulwark_fnc_endOfficerHunt;
                if (_reason == "workerFailed") then {diag_log format ["Bulwark Officer Hunt %1: producer failed; recovering", _id]};
            } else {
                if (_state == "active") then {
                    private _group = _r get "postGroup";
                    if (!isNull _group) then {
                        [_group, _wave, _id, _r get "position"] remoteExecCall ["bulwark_fnc_controlOfficerPost", groupOwner _group];
                    };
                };
            };
        };
        if ((_r get "state") == "closing" && {scriptDone (_r getOrDefault ["pendingJob", scriptNull])} &&
            {scriptDone (_r getOrDefault ["worker", scriptNull])}) then {BW_OFFICER_HUNT = createHashMap};
    };
};
