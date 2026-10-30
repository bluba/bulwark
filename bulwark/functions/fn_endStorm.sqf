// Wave-bound, idempotent cleanup; -1 explicitly ends whichever storm is active.
params [["_wave", -1]];
if (!isServer || {isRemoteExecuted}) exitWith {false};
private _ended = false;
isNil {
    private _state = missionNamespace getVariable ["BW_STORM_STATE", [0, false, 0]];
    if ((_state select 1) && {_wave < 0 || {_wave == (_state select 0)}}) then {
        private _saved = missionNamespace getVariable ["BW_STORM_SAVED", [0.5, 0, 0]];
        // Publish closure before removing targets so queued effects reject stale work.
        missionNamespace setVariable ["BW_STORM_STATE", [_state select 0, false, _saved select 2], true];
        {deleteVehicle (_x select 0)} forEach (missionNamespace getVariable ["BW_STORM_TARGETS", []]);
        BW_STORM_TARGETS = [];
        0 setOvercast (_saved select 0);
        0 setRain (_saved select 1);
        0 setLightnings (_saved select 2);
        forceWeatherChange;
        BW_STORM_SAVED = [];
        private _job = missionNamespace getVariable ["BW_STORM_JOB", scriptNull];
        BW_STORM_JOB = scriptNull;
        _ended = true;
        if (!scriptDone _job) then {terminate _job};
    };
};
_ended
