/* Disposable initialized idle server/editor only:
   [] execVM "tests\debugForceWave.sqf";
   No hostiles, caches, storm, FOB, officer event or pending spawn work.
   Tests real administrative cleanup and cancellation of a capacity wait. Does
   not start the full mission loop. Creates/deletes temporary units/vehicles. */
if (!isServer || {!canSuspend}) exitWith {};
if (missionNamespace getVariable ["runMissionLoop", false] ||
    {(allUnits findIf {alive _x && {side group _x in [east, resistance]}}) >= 0} ||
    {count (missionNamespace getVariable ["BW_OFFICER_HUNT", createHashMap]) > 0} ||
    {!((missionNamespace getVariable ["BW_ACTIVE_FOBS", []]) isEqualTo [])} ||
    {!((missionNamespace getVariable ["BW_SPAWN_QUEUE", []]) isEqualTo [])} ||
    {((missionNamespace getVariable ["BW_SPAWN_JOBS", []]) findIf {!scriptDone _x}) >= 0} ||
    {(missionNamespace getVariable ["BW_STORM_STATE", [0,false,0]]) select 1} ||
    {count (missionNamespace getVariable ["BW_SUPPLY_CACHE", createHashMap]) > 0} ||
    {count (missionNamespace getVariable ["BW_ENGINEERING_CACHE", createHashMap]) > 0}) exitWith {
    diag_log "Debug force test requires an initialized idle session without active event/spawn work";
};
private _names = ["runMissionLoop","missionExtract","buildPhase","attkWave","BW_ENEMY_LIMIT","BW_SPAWN_SERIAL",
    "BW_SPAWN_JOBS","BW_SPAWN_QUEUE","BW_INFANTRY_REMAINING","BW_DEBUG_NEXT_SPECIAL","BW_DEBUG_FORCED_WAVE",
    "BW_DEBUG_TRANSITION","BW_READY_OPEN","BW_READY_STATE","BW_READY_VOTERS","BW_PREP_DEADLINE",
    "BW_ACTIVE_FOBS","BW_FOB_SETUP_PENDING","BW_WAVE_PROJECTILES"];
private _saved = _names apply {[!isNil _x, missionNamespace getVariable [_x,false]]};
private _failures = [];
private _check = {params ["_ok","_label"]; if (!_ok) then {_failures pushBack _label; diag_log ("DEBUG FORCE FAIL: " + _label)}};
runMissionLoop = true; missionExtract = false; buildPhase = false; attkWave = 100;
BW_ENEMY_LIMIT = 1; BW_SPAWN_SERIAL = 0; BW_SPAWN_JOBS = []; BW_SPAWN_QUEUE = [];
BW_INFANTRY_REMAINING = 10; BW_WAVE_PROJECTILES = []; BW_ACTIVE_FOBS = [];
BW_DEBUG_NEXT_SPECIAL = "nightWave"; BW_DEBUG_TRANSITION = true;
private _enemyGroup = createGroup [east,true];
private _friendlyGroup = createGroup [west,true];
private _enemy = _enemyGroup createUnit ["O_Soldier_F", [1000,1000,0], [], 0, "NONE"];
private _friendly = _friendlyGroup createUnit ["B_Soldier_F", [1000,1000,0], [], 0, "NONE"];
{_x disableAI "ALL"} forEach [_enemy,_friendly];
private _emptyEnemyVehicle = createVehicle ["O_MRAP_02_F", [1020,1000,0], [], 0, "NONE"];
_emptyEnemyVehicle setVariable ["bw_hostileWave",100];
private _friendlyVehicle = createVehicle ["B_MRAP_01_F", [1040,1000,0], [], 0, "NONE"];
private _pending = [] spawn {
    private _g = [[[1000,1000,0],east,["O_Soldier_F"]],"group",100] call bulwark_fnc_spawnLimited;
    if (!isNull _g) then {diag_log "DEBUG FORCE FAIL: cancelled request spawned"; {deleteVehicle _x} forEach units _g; deleteGroup _g};
};
BW_SPAWN_JOBS pushBack _pending;
sleep 0.5;
[!scriptDone _pending && {count BW_SPAWN_QUEUE == 1}, "capacity request initially waits"] call _check;
// An orphan ticket must not keep the transition stuck after its producer died.
BW_SPAWN_QUEUE pushBack [999,100,1,false,scriptNull];
[[] call bulwark_fnc_debugAdvanceWave, "transition cleanup completed"] call _check;
[buildPhase && {attkWave == 100}, "cleanup closes combat but leaves wave increment to mission loop"] call _check;
[scriptDone _pending && {BW_SPAWN_QUEUE isEqualTo []}, "waiting and orphan tickets drain"] call _check;
[isNull _enemy && {isNull _emptyEnemyVehicle}, "current hostile unit and tagged empty vehicle removed"] call _check;
[alive _friendly && {alive _friendlyVehicle}, "friendly unit and vehicle preserved"] call _check;
[BW_INFANTRY_REMAINING == 0 && {BW_DEBUG_NEXT_SPECIAL == ""} && {BW_DEBUG_FORCED_WAVE isEqualTo [101,"nightWave"]}, "next-wave override armed once"] call _check;
[[101,"nightWave"] call bulwark_fnc_debugForced, "matching forced type recognized"] call _check;
[!([100,"nightWave"] call bulwark_fnc_debugForced) && {!([101,"arty"] call bulwark_fnc_debugForced)}, "override cannot affect another wave/type"] call _check;
{deleteVehicle _x} forEach [_enemy,_friendly,_emptyEnemyVehicle,_friendlyVehicle];
{deleteGroup _x} forEach [_enemyGroup,_friendlyGroup];
{private _v = _saved select _forEachIndex; if (_v select 0) then {missionNamespace setVariable [_x,_v select 1]} else {missionNamespace setVariable [_x,nil]}} forEach _names;
{if (!isNil _x) then {publicVariable _x}} forEach ["buildPhase","BW_READY_STATE"];
diag_log format ["Debug force tests complete: %1",_failures];
