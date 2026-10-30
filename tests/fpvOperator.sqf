/* Disposable idle hosted/editor server with Ukraine FPV Drone, mission functions,
   a living conscious WEST human on foot, Bulwark and a valid hidden site:
   [] execVM "tests\fpvOperator.sqf";
   No running mission loop, hostile units, active FOB/officer/FPV or capacity jobs.
   Tests real producer, native protected drone spawn, target policy and cleanup.
   Does not intentionally detonate. Restores globals and visibility predicate. */
if (!isServer || {!canSuspend}) exitWith {};
if (missionNamespace getVariable ["runMissionLoop",false] ||
    {{alive _x && {side group _x in [east,resistance]}} count allUnits > 0} ||
    {count (missionNamespace getVariable ["BW_FPV_OPERATOR",createHashMap]) > 0} ||
    {count (missionNamespace getVariable ["BW_OFFICER_HUNT",createHashMap]) > 0} ||
    {!((missionNamespace getVariable ["BW_ACTIVE_FOBS",[]]) isEqualTo [])} ||
    {!((missionNamespace getVariable ["BW_SPAWN_QUEUE",[]]) isEqualTo [])} ||
    {((missionNamespace getVariable ["BW_SPAWN_JOBS",[]]) findIf {!scriptDone _x}) >= 0} ||
    {isNil "bulwarkBox"} || {isNull bulwarkBox} ||
    {!(["available"] call bulwark_fnc_fpvAdapter)}) exitWith {diag_log "FPV test: unmet idle/addon prerequisites"};
private _people = ([] call bulwark_fnc_humanPlayers) select {alive _x && {side group _x == west} && {isNull objectParent _x} && {lifeState _x != "INCAPACITATED"}};
if (_people isEqualTo []) exitWith {diag_log "FPV test needs a conscious WEST human on foot"};
private _site = [];
{
    private _p = +_x; _p set [2,0];
    if ([_p,getPosATL bulwarkBox] call bulwark_fnc_fpvSiteClear) exitWith {_site = _p};
} forEach ([] call bulwark_fnc_fpvSites);
if (_site isEqualTo []) exitWith {diag_log "FPV test: no valid hidden site; configure BW_FPV_SITES near Bulwark"};
private _names = ["runMissionLoop","missionExtract","buildPhase","attkWave","BW_DEBUG_FORCED_WAVE",
    "BW_ENEMY_LIMIT","BW_SPAWN_QUEUE","BW_SPAWN_SERIAL","BW_SPAWN_JOBS","waveUnits","defectorWave",
    "BW_FPV_OPERATOR","BW_FPV_SERIAL","BW_FPV_LAST_WAVE","BW_FPV_STATUS","BW_FPV_RESULT","BW_FPV_SITES",
    "BW_FPV_CAP","BW_FPV_GUARDS","BW_FPV_ENABLED","HOSTILE_LEVEL_2"];
private _saved = _names apply {[!isNil _x,missionNamespace getVariable [_x,false]]};
private _visible = bulwark_fnc_fpvVisible;
private _failures = [];
private _check = {params ["_ok","_label"]; if (!_ok) then {_failures pushBack _label; diag_log ("FPV FAIL: " + _label)}};
private _wait = {params ["_condition",["_timeout",10]]; private _until=time+_timeout; waitUntil {sleep 0.1; call _condition || {time >= _until}}; call _condition};
runMissionLoop=true; missionExtract=false; buildPhase=false; attkWave=100;
BW_DEBUG_FORCED_WAVE=[100,"fpvOperator"]; BW_ENEMY_LIMIT=40;
BW_SPAWN_QUEUE=[]; BW_SPAWN_SERIAL=0; BW_SPAWN_JOBS=[]; waveUnits=[[],[],[]]; defectorWave=false;
BW_FPV_OPERATOR=createHashMap; BW_FPV_SERIAL=0; BW_FPV_LAST_WAVE=-1; BW_FPV_STATUS=[]; BW_FPV_SITES=[_site];
BW_FPV_CAP=2; BW_FPV_GUARDS=2; BW_FPV_ENABLED=true; HOSTILE_LEVEL_2=["O_Soldier_F"];
BW_FPV_CAP=3;
[count ([] call bulwark_fnc_fpvSettings) == 0,"invalid hard cap rejected"] call _check;
BW_FPV_CAP=2;
[!([100,["officerHunt"]] call bulwark_fnc_fpvAvailable) && {!([100,["encampment"]] call bulwark_fnc_fpvAvailable)},"objective exclusion"] call _check;
[!([100,["fpvOperator"]] call bulwark_fnc_fobAvailable) && {!([100,["fpvOperator"]] call bulwark_fnc_officerHuntAvailable)},"reciprocal exclusion"] call _check;
[[100] call bulwark_fnc_startFpv,"start admitted"] call _check;
[!([100] call bulwark_fnc_startFpv),"setup singleton"] call _check;
[[{(BW_FPV_OPERATOR getOrDefault ["state",""]) == "active"},40] call _wait,"station activated"] call _check;
private _r = BW_FPV_OPERATOR;
if ((_r getOrDefault ["state",""]) == "active") then {
    [count (_r get "units") == 3 && {count BW_FPV_STATUS == 5},"operator/guards and public snapshot"] call _check;
    [!([(_r get "id") - 1,"stale"] call bulwark_fnc_endFpv) && {(_r get "state") == "active"},"stale cleanup ignored"] call _check;
    _r set ["nextSpawn",time+9999];
    for "_i" from 1 to 4 do {[_r] call bulwark_fnc_fpvSpawnDrone};
    private _cap = if (count (([] call bulwark_fnc_humanPlayers) select {alive _x && {side group _x == west}}) <= 1) then {1} else {2};
    [count (_r get "drones") == _cap,"hard cap including solo limit"] call _check;
    private _objects = (_r get "drones") apply {_x get "object"};
    sleep 1;
    [(_objects findIf {!(_x getVariable ["UA_FPV_PayloadSwapProtected",false])}) < 0,"native init cannot rearm drones"] call _check;
    [(_objects findIf {count crew _x > 0}) < 0,"crewless separate capacity"] call _check;
    if !((_r get "drones") isEqualTo []) then {
        // Isolate allocation policy from terrain while keeping actual players/UIDs.
        isNil {
            bulwark_fnc_fpvVisible = {true};
            private _d = (_r get "drones") select 0;
            {_x set ["target",objNull]} forEach (_r get "drones");
            _r set ["history",createHashMap];
            private _target = [_r,_d] call bulwark_fnc_fpvTarget;
            [!isNull _target,"eligible target selected"] call _check;
            private _other = createHashMapFromArray [["object",_d get "object"],["target",objNull]];
            private _second = [_r,_other] call bulwark_fnc_fpvTarget;
            [isNull _second || {!(_second isEqualTo _target)},"busy target excluded"] call _check;
            _d set ["target",objNull];
            private _again = [_r,_other] call bulwark_fnc_fpvTarget;
            [isNull _again || {!(_again isEqualTo _target)},"UID cooldown enforced"] call _check;
            bulwark_fnc_fpvVisible = _visible;
        };
    };
    // Deletion follows the same reliable alive predicate as a killed operator.
    deleteVehicle (_r get "operator");
    [] call bulwark_fnc_updateFpv;
    [(_r get "state") == "closing" && {BW_FPV_STATUS isEqualTo []},"operator deletion closes station"] call _check;
    [!([_r] call bulwark_fnc_fpvSpawnDrone),"closed station cannot launch"] call _check;
    sleep 0.2;
    [(_objects findIf {!isNull _x}) < 0 && {isNull (_r get "device")},"drones/device removed without detonation"] call _check;
    [((_r get "units") findIf {alive _x && {(_x getVariable ["aiMode",""]) != "rush"}}) < 0,"guards released"] call _check;
};
// Drain the first producer before exercising independent closure conditions.
[_r getOrDefault ["id",-1],"testClose"] call bulwark_fnc_endFpv;
[{scriptDone (_r getOrDefault ["worker",scriptNull])},40] call _wait;
{deleteVehicle _x} forEach (_r getOrDefault ["units",[]]);
deleteGroup (_r getOrDefault ["group",grpNull]);
[] call bulwark_fnc_updateFpv;
{
    private _case = _x;
    attkWave = attkWave + 3;
    BW_DEBUG_FORCED_WAVE = [attkWave,"fpvOperator"];
    missionExtract = false;
    private _oldId = _r getOrDefault ["id",-1];
    [[attkWave] call bulwark_fnc_startFpv,"restart for " + _case] call _check;
    [[{(BW_FPV_OPERATOR getOrDefault ["state",""]) == "active"},40] call _wait,"active for " + _case] call _check;
    _r = BW_FPV_OPERATOR;
    if ((_r getOrDefault ["state",""]) == "active") then {
        _r set ["nextSpawn",time+9999];
        [!([_oldId,"stale"] call bulwark_fnc_endFpv),"old instance cannot close " + _case] call _check;
        if (_case != "exhausted") then {[_r] call bulwark_fnc_fpvSpawnDrone};
        private _owned = (_r get "drones") apply {_x get "object"};
        switch (_case) do {
            case "device": {deleteVehicle (_r get "device")};
            case "expired": {_r set ["deadline",time-1]};
            case "relocated": {_r set ["origin",(getPosATL bulwarkBox) vectorAdd [200,0,0]]};
            case "exhausted": {_r set ["starts",(_r get "settings") get "START_LIMIT"]};
            case "extraction": {missionExtract=true};
        };
        [] call bulwark_fnc_updateFpv;
        [(_r get "state") == "closing" && {BW_FPV_STATUS isEqualTo []},"closure: " + _case] call _check;
        sleep 0.2;
        [(_owned findIf {!isNull _x}) < 0,"owned drone cleanup: " + _case] call _check;
    };
    [_r getOrDefault ["id",-1],"testClose"] call bulwark_fnc_endFpv;
    [{scriptDone (_r getOrDefault ["worker",scriptNull])},40] call _wait;
    {deleteVehicle _x} forEach (_r getOrDefault ["units",[]]);
    deleteGroup (_r getOrDefault ["group",grpNull]);
    [] call bulwark_fnc_updateFpv;
} forEach ["device","expired","relocated","exhausted","extraction"];
// Explicit ending is idempotent and escalates any previous handoff to deletion.
missionExtract=true; buildPhase=true;
[_r getOrDefault ["id",-1],"testCleanup"] call bulwark_fnc_endFpv;
[[{(BW_SPAWN_JOBS findIf {!scriptDone _x}) < 0 && {BW_SPAWN_QUEUE isEqualTo []}},40] call _wait,"producer and capacity drain"] call _check;
bulwark_fnc_fpvVisible = _visible;
{{deleteVehicle _x} forEach units _x; deleteGroup _x} forEach [(_r getOrDefault ["group",grpNull])];
[] call bulwark_fnc_updateFpv;
[count BW_FPV_OPERATOR == 0,"record retired after worker completion"] call _check;
{private _v = _saved select _forEachIndex; missionNamespace setVariable [_x,if (_v select 0) then {_v select 1} else {nil}]} forEach _names;
publicVariable "BW_FPV_STATUS";
diag_log format ["FPV regression complete: %1",_failures];
