// Persistent weather effect: never register its worker as a wave-completion job.
params ["_wave"];
if (!isServer || {isRemoteExecuted} || {!([_wave] call bulwark_fnc_waveActive)} ||
    {("SPECIAL_WAVES" call BIS_fnc_getParamValue) == 0 && {!([_wave, "thunderstorm"] call bulwark_fnc_debugForced)}}) exitWith {false};
private _started = false;
isNil {
    private _state = missionNamespace getVariable ["BW_STORM_STATE", [0, false, 0]];
    if (!(_state select 1) && {[_wave] call bulwark_fnc_waveActive}) then {
        BW_STORM_SAVED = [overcast, rain, lightnings];
        BW_STORM_TARGETS = [];
        0 setOvercast 1;
        0 setRain 0.85;
        0 setLightnings 0.7;
        forceWeatherChange;
        missionNamespace setVariable ["BW_STORM_STATE", [_wave, true, 0.7], true];
        BW_STORM_JOB = [_wave] execVM "hostiles\thunderstorm.sqf";
        _started = true;
    };
};
if (_started) then {
    ["TaskAssigned", ["Thunderstorm", "Heavy rain and lightning. Watch for nearby ground strikes."]] remoteExec ["BIS_fnc_showNotification", 0];
};
_started
