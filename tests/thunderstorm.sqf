/* Idle disposable server/editor only, mission functions loaded, no running loop
   or storm: [] execVM "tests\thunderstorm.sqf";
   Changes real weather temporarily. Native lightning is stubbed (no damage).
   Tests actual start/end/worker and strike guards; dedicated visuals/JIP and
   native damage locality still require two-client acceptance. */
if (!isServer || {!canSuspend}) exitWith {};
if (missionNamespace getVariable ["runMissionLoop", false] ||
    {(missionNamespace getVariable ["BW_STORM_STATE", [0, false, 0]]) select 1}) exitWith {
    diag_log "Thunderstorm test requires an idle mission without an active storm";
};
private _names = ["runMissionLoop", "missionExtract", "buildPhase", "attkWave",
    "BW_STORM_STATE", "BW_STORM_SAVED", "BW_STORM_TARGETS", "BW_STORM_JOB", "BW_SPAWN_JOBS"];
private _saved = _names apply {[!isNil _x, missionNamespace getVariable [_x, false]]};
private _weather = [overcast, rain, lightnings];
private _failures = [];
private _check = {
    params ["_ok", "_label"];
    if (!_ok) then {_failures pushBack _label; diag_log ("STORM FAIL: " + _label)};
};
private _nativeLightning = BIS_fnc_moduleLightning;
private _strikeCalls = 0;
BIS_fnc_moduleLightning = {_strikeCalls = _strikeCalls + 1};
runMissionLoop = true; missionExtract = false; buildPhase = false; attkWave = 50;
BW_STORM_STATE = [0, false, lightnings]; BW_STORM_SAVED = [];
BW_STORM_TARGETS = []; BW_STORM_JOB = scriptNull; BW_SPAWN_JOBS = [];
private _enabled = ("SPECIAL_WAVES" call BIS_fnc_getParamValue) != 0;
private _started = [50] call bulwark_fnc_startStorm;
[_started isEqualTo _enabled, "specials setting gates direct storm startup"] call _check;
if (_enabled) then {
    private _job = BW_STORM_JOB;
    private _captured = +BW_STORM_SAVED;
    [BW_STORM_STATE isEqualTo [50, true, 0.7], "public active snapshot"] call _check;
    [_captured isEqualTo _weather, "original weather captured before change"] call _check;
    [!([50] call bulwark_fnc_startStorm) && {BW_STORM_JOB isEqualTo _job} &&
        {BW_STORM_SAVED isEqualTo _captured}, "duplicate startup preserves worker and saved weather"] call _check;
    [BW_SPAWN_JOBS isEqualTo [], "persistent storm never blocks wave completion"] call _check;
    [!([49] call bulwark_fnc_endStorm) && {(BW_STORM_STATE select 1)}, "stale cleanup cannot end current storm"] call _check;

    private _target = createVehicle ["Land_HelipadEmpty_F", [1000,1000,0], [], 0, "CAN_COLLIDE"];
    _target setVariable ["bw_stormTarget", true, true];
    BW_STORM_TARGETS pushBack [_target, time + 10];
    [_target, 50, serverTime] call bulwark_fnc_stormStrike;
    [_strikeCalls == 1, "active current-wave strike reaches native effect once"] call _check;
    [_target, 50, serverTime] call bulwark_fnc_stormStrike;
    [_strikeCalls == 1, "duplicate dispatch cannot repeat native effect"] call _check;
    _target setVariable ["bw_stormRendered", false];
    [_target, 49, serverTime] call bulwark_fnc_stormStrike;
    [_target, 50, serverTime - 6] call bulwark_fnc_stormStrike;
    [objNull, 50, serverTime] call bulwark_fnc_stormStrike;
    _target setVariable ["bw_stormTarget", false, true];
    [_target, 50, serverTime] call bulwark_fnc_stormStrike;
    _target setVariable ["bw_stormTarget", true, true];
    buildPhase = true;
    [_target, 50, serverTime] call bulwark_fnc_stormStrike;
    [_strikeCalls == 1, "stale, expired, null, untagged and preparation strikes rejected"] call _check;
    [[50] call bulwark_fnc_endStorm, "wave cleanup commits"] call _check;
    [!(BW_STORM_STATE select 1) && {(BW_STORM_STATE select 2) == (_weather select 2)}, "inactive snapshot restores lightning setting"] call _check;
    [isNull _target && {BW_STORM_TARGETS isEqualTo []} && {scriptDone _job}, "cleanup deletes targets and terminates worker"] call _check;
    [!([50] call bulwark_fnc_endStorm), "repeat cleanup is harmless"] call _check;
    [!([50] call bulwark_fnc_startStorm), "preparation rejects startup"] call _check;

    buildPhase = false; attkWave = 51;
    [[51] call bulwark_fnc_startStorm, "next combat can start a new storm"] call _check;
    missionExtract = true;
    private _deadline = time + 3;
    waitUntil {sleep 0.1; !(BW_STORM_STATE select 1) || {time >= _deadline}};
    [!(BW_STORM_STATE select 1) && {BW_STORM_TARGETS isEqualTo []}, "worker cleans up on extraction"] call _check;
};
[] call bulwark_fnc_endStorm;
BIS_fnc_moduleLightning = _nativeLightning;
0 setOvercast (_weather select 0); 0 setRain (_weather select 1);
0 setLightnings (_weather select 2); forceWeatherChange;
missionNamespace setVariable ["BW_STORM_STATE", [0, false, _weather select 2], true];
{private _value = _saved select _forEachIndex; if (_value select 0) then {missionNamespace setVariable [_x, _value select 1]} else {missionNamespace setVariable [_x, nil]}} forEach _names;
// Restore the authoritative client snapshot too after testing public transitions.
if (!isNil "BW_STORM_STATE") then {publicVariable "BW_STORM_STATE"};
diag_log format ["Thunderstorm tests complete: %1", _failures];
