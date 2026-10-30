/* Run in an isolated idle editor/server with this mission's functions/config loaded:
   [] execVM "tests\fob.sqf";
   Disable the normal mission loop first. Uses real FOB scripts and capacity gateway.
   Run once with specials enabled and once with specials disabled. No mods needed
   for test infantry; LAMBS is required for the defender handoff scenario.
*/
if (!isServer || {!canSuspend}) exitWith {};
if (missionNamespace getVariable ["runMissionLoop", false] ||
    {{alive _x && {side group _x in [east, resistance]}} count allUnits > 0} ||
    {!((missionNamespace getVariable ["BW_ACTIVE_FOBS", []]) isEqualTo [])}) exitWith {
    diag_log "FOB test requires an idle mission with no hostile units or FOBs";
};
private _enabled = ("SPECIAL_WAVES" call BIS_fnc_getParamValue) != 0;
if (_enabled && {isNil "lambs_wp_fnc_taskPatrol"}) exitWith {diag_log "FOB test requires LAMBS"};
private _names = ["runMissionLoop", "missionExtract", "buildPhase", "attkWave", "BW_ENEMY_LIMIT",
    "BW_SPAWN_QUEUE", "BW_SPAWN_SERIAL", "BW_SPAWN_JOBS", "BW_ACTIVE_FOBS", "BW_FOB_LAST_WAVE",
    "BW_FOB_SETUP_PENDING", "BW_FOB_COOLDOWN_WAVES", "HOSTILE_LEVEL_3", "DEFECTOR_INF", "defectorWave", "waveUnits"];
private _saved = _names apply {[!isNil _x, missionNamespace getVariable [_x, false]]};
BW_fobTestFailures = [];
private _check = {
    params ["_ok", "_label"];
    if (!_ok) then {BW_fobTestFailures pushBack _label; diag_log ("FOB FAIL: " + _label)};
};
private _wait = {
    params ["_condition", ["_timeout", 20]];
    private _deadline = time + _timeout;
    waitUntil {sleep 0.1; call _condition || {time >= _deadline}};
    call _condition
};
runMissionLoop = true; missionExtract = false; buildPhase = false; attkWave = 7;
BW_ENEMY_LIMIT = 10; BW_SPAWN_QUEUE = []; BW_SPAWN_SERIAL = 0; BW_SPAWN_JOBS = [];
BW_ACTIVE_FOBS = []; BW_FOB_LAST_WAVE = -1; BW_FOB_SETUP_PENDING = false; BW_FOB_COOLDOWN_WAVES = 2;
HOSTILE_LEVEL_3 = ["O_Soldier_F"]; DEFECTOR_INF = ["I_Soldier_F"]; defectorWave = false;
waveUnits = [[], [], []];
private _jobs = [];
private _blockers = createGroup [east, true];
private _testGroups = [];

if (!_enabled) then {
    [!([7] call bulwark_fnc_fobAvailable), "specials Off excludes FOB"] call _check;
    private _job = [[7], "hostiles\createEmplacement.sqf"] call bulwark_fnc_queueHostiles;
    _jobs pushBack _job;
    [[{scriptDone _job}] call _wait, "specials Off rejects direct producer"] call _check;
    [BW_ACTIVE_FOBS isEqualTo [] && {BW_FOB_LAST_WAVE == -1}, "disabled producer has no cache/cooldown"] call _check;
} else {
    [!([6] call bulwark_fnc_fobAvailable), "no FOB before wave 7"] call _check;
    [[7] call bulwark_fnc_fobAvailable, "wave 7 eligible"] call _check;
    [[30] call bulwark_fnc_fobAvailable, "late waves eligible"] call _check;
    [!([7, ["encampment"]] call bulwark_fnc_fobAvailable), "duplicate plan excluded"] call _check;
    BW_FOB_SETUP_PENDING = true;
    [!([30] call bulwark_fnc_fobAvailable), "pending setup holds singleton slot"] call _check;
    BW_FOB_SETUP_PENDING = false;
    // Invalid content must not start cooldown or leave a reservation behind.
    HOSTILE_LEVEL_3 = [];
    private _invalid = [[7], "hostiles\createEmplacement.sqf"] call bulwark_fnc_queueHostiles;
    _jobs pushBack _invalid;
    [[{scriptDone _invalid}] call _wait, "invalid-class producer finishes"] call _check;
    [BW_FOB_LAST_WAVE == -1 && {!BW_FOB_SETUP_PENDING}, "failed setup leaves eligibility intact"] call _check;
    HOSTILE_LEVEL_3 = ["O_Soldier_F"];
    // Fill capacity: the FOB must register its cache and wait without spawning troops.
    for "_i" from 1 to 10 do {
        private _unit = _blockers createUnit ["O_Soldier_F", [1000,1000,0], [], 0, "NONE"];
        _unit disableAI "ALL"; _unit allowDamage false;
    };
    private _first = [[7], "hostiles\createEmplacement.sqf"] call bulwark_fnc_queueHostiles;
    private _duplicate = [[7], "hostiles\createEmplacement.sqf"] call bulwark_fnc_queueHostiles;
    _jobs append [_first, _duplicate];
    [[{count BW_ACTIVE_FOBS == 1 && {count BW_SPAWN_QUEUE == 1}}] call _wait, "one cache, one capacity waiter"] call _check;
    [[{(scriptDone _first) != (scriptDone _duplicate)}] call _wait, "only one concurrent producer survives admission"] call _check;
    [!([30] call bulwark_fnc_fobAvailable), "live cache blocks even after cooldown"] call _check;
    private _cache = BW_ACTIVE_FOBS param [0, objNull];
    deleteVehicle _cache;
    [[{scriptDone _first && {scriptDone _duplicate}}, 10] call _wait, "deleted cache cancels waiting producer and finishes handoff"] call _check;
    [BW_SPAWN_QUEUE isEqualTo [] && {(waveUnits select 0) isEqualTo []}, "no late infantry or leaked capacity request"] call _check;
    [BW_ACTIVE_FOBS isEqualTo [], "destroyed cache no longer blocks completion"] call _check;
    [!([8] call bulwark_fnc_fobAvailable) && {!([9] call bulwark_fnc_fobAvailable)} && {[10] call bulwark_fnc_fobAvailable}, "two intervening waves: 7 -> 10"] call _check;
    BW_FOB_COOLDOWN_WAVES = 0;
    [!([7] call bulwark_fnc_fobAvailable) && {[8] call bulwark_fnc_fobAvailable}, "zero cooldown still excludes same-wave repeat"] call _check;
    BW_FOB_COOLDOWN_WAVES = 2;
    buildPhase = true; sleep 2;

    // Extraction with a live cache and full capacity must clean up, not spawn.
    attkWave = 10; buildPhase = false;
    private _cancel = [[10], "hostiles\createEmplacement.sqf"] call bulwark_fnc_queueHostiles;
    _jobs pushBack _cancel;
    [[{count BW_ACTIVE_FOBS == 1 && {count BW_SPAWN_QUEUE == 1}}] call _wait, "later-wave FOB waits at capacity"] call _check;
    _cache = BW_ACTIVE_FOBS param [0, objNull];
    missionExtract = true;
    [[{scriptDone _cancel}, 10] call _wait, "extraction cancels FOB job"] call _check;
    [isNull _cache && {BW_ACTIVE_FOBS isEqualTo []} && {BW_SPAWN_QUEUE isEqualTo []}, "extraction removes cache and releases reservations"] call _check;
    buildPhase = true; sleep 2;
    {deleteVehicle _x} forEach units _blockers;

    // Real defenders must be handed back to the assault controller after cache loss.
    attkWave = 13; missionExtract = false; buildPhase = false; BW_ENEMY_LIMIT = 40;
    private _handoff = [[13], "hostiles\createEmplacement.sqf"] call bulwark_fnc_queueHostiles;
    _jobs pushBack _handoff;
    [[{count (waveUnits select 0) == 30}, 40] call _wait, "three garrison squads spawn through capacity gateway"] call _check;
    private _defenders = +(waveUnits select 0);
    {_x allowDamage false; _testGroups pushBackUnique (group _x)} forEach _defenders;
    _cache = BW_ACTIVE_FOBS param [0, objNull];
    _cache setDamage 1;
    [[{scriptDone _handoff}, 10] call _wait, "destroyed cache finishes registered producer during combat"] call _check;
    [count _defenders == 30 && {(_defenders findIf {_x getVariable ["bw_stationary", false]}) < 0} &&
        {(_testGroups findIf {_x getVariable ["bw_scriptedMovement", false]}) < 0}, "surviving defenders released from garrison"] call _check;
    [BW_ACTIVE_FOBS isEqualTo [], "handoff clears mandatory objective"] call _check;
};

// Allow normal wave cancellation and detached scenery cleanup before restoring state.
buildPhase = true; missionExtract = true;
[{(_jobs findIf {!scriptDone _x}) < 0}, 10] call _wait;
{if (!scriptDone _x) then {terminate _x; BW_fobTestFailures pushBack "producer timed out during cleanup"}} forEach _jobs;
sleep 2;
{_testGroups pushBackUnique (group _x); deleteVehicle _x} forEach (waveUnits select 0);
{deleteVehicle _x} forEach units _blockers;
deleteGroup _blockers;
{deleteGroup _x} forEach _testGroups;
[(allMapMarkers findIf {_x find "BulwarkFOB_" == 0}) < 0, "FOB markers cleaned"] call _check;
[!BW_FOB_SETUP_PENDING, "no setup reservation left"] call _check;
{private _value = _saved select _forEachIndex; if (_value select 0) then {missionNamespace setVariable [_x, _value select 1]} else {missionNamespace setVariable [_x, nil]}} forEach _names;
diag_log format ["FOB tests complete: %1", BW_fobTestFailures];
