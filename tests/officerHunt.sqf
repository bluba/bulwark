/* Idle disposable server/editor with a living human, mission functions and LAMBS:
   [] execVM "tests\officerHunt.sqf";
   No normal mission loop/hostiles/FOB/officer event. Uses real producers/gateway,
   temporary vanilla enemy squads and a real validated site. Restores globals and
   the site selector. Requires Specials On; run predicate rejection with Off too. */
if (!isServer || {!canSuspend}) exitWith {};
if (missionNamespace getVariable ["runMissionLoop", false] ||
    {{alive _x && {side group _x in [east,resistance]}} count allUnits > 0} ||
    {count (missionNamespace getVariable ["BW_OFFICER_HUNT",createHashMap]) > 0} ||
    {!((missionNamespace getVariable ["BW_ACTIVE_FOBS",[]]) isEqualTo [])} ||
    {isNil "lambs_wp_fnc_taskPatrol"}) exitWith {diag_log "Officer test requires idle empty hostile battlefield and LAMBS"};
private _site = [([] call bulwark_fnc_spawnAnchor)] call bulwark_fnc_findOfficerPost;
if (_site isEqualTo []) exitWith {diag_log "Officer test needs a valid outdoor site"};
private _names = ["runMissionLoop","missionExtract","buildPhase","attkWave","BW_ENEMY_LIMIT","BW_INFANTRY_REMAINING",
    "BW_SPAWN_QUEUE","BW_SPAWN_SERIAL","BW_SPAWN_JOBS","waveUnits","defectorWave","HOSTILE_LEVEL_2","HOSTILE_LEVEL_3",
    "BW_ACTIVE_FOBS","BW_FOB_SETUP_PENDING","BW_FOB_LAST_WAVE","BW_OFFICER_ENABLED","BW_OFFICER_MIN_WAVE","BW_OFFICER_COOLDOWN_WAVES",
    "BW_OFFICER_GUARDS","BW_OFFICER_TEAM_SIZE","BW_OFFICER_TEAM_CAP","BW_OFFICER_INTERVAL","BW_OFFICER_TIMEOUT","BW_OFFICER_LIFETIME",
    "BW_OFFICER_CLASSES","BW_OFFICER_HUNT","BW_OFFICER_SERIAL","BW_OFFICER_LAST_WAVE","BW_OFFICER_STATUS","BW_OFFICER_RESULT"];
private _saved = _names apply {[!isNil _x, missionNamespace getVariable [_x,false]]};
private _selector = bulwark_fnc_findOfficerPost;
bulwark_fnc_findOfficerPost = {+_site};
private _failures = [];
private _check = {params ["_ok","_label"]; if (!_ok) then {_failures pushBack _label; diag_log ("OFFICER FAIL: " + _label)}};
private _wait = {params ["_predicate",["_seconds",10]]; private _until = time + _seconds; waitUntil {sleep 0.1; call _predicate || {time >= _until}}; call _predicate};
runMissionLoop=true; missionExtract=false; buildPhase=false; attkWave=100;
BW_ENEMY_LIMIT=40; BW_INFANTRY_REMAINING=123; BW_SPAWN_QUEUE=[]; BW_SPAWN_SERIAL=0; BW_SPAWN_JOBS=[]; waveUnits=[[],[],[]];
BW_ACTIVE_FOBS=[]; BW_FOB_SETUP_PENDING=false; BW_FOB_LAST_WAVE=-1;
BW_OFFICER_ENABLED=true; BW_OFFICER_MIN_WAVE=10; BW_OFFICER_COOLDOWN_WAVES=2;
BW_OFFICER_GUARDS=1; BW_OFFICER_TEAM_SIZE=4; BW_OFFICER_TEAM_CAP=2; BW_OFFICER_INTERVAL=90; BW_OFFICER_TIMEOUT=60; BW_OFFICER_LIFETIME=600;
BW_OFFICER_CLASSES=["O_officer_F"]; HOSTILE_LEVEL_2=["O_Soldier_F"]; HOSTILE_LEVEL_3=["O_Soldier_F"]; defectorWave=false;
BW_OFFICER_HUNT=createHashMap; BW_OFFICER_SERIAL=0; BW_OFFICER_LAST_WAVE=-1; BW_OFFICER_STATUS=[];
private _enabled = ("SPECIAL_WAVES" call BIS_fnc_getParamValue) != 0;
[!([9] call bulwark_fnc_officerHuntAvailable),"minimum wave"] call _check;
[!([100,["encampment"]] call bulwark_fnc_officerHuntAvailable),"FOB-first plan exclusion"] call _check;
[!([100,["officerHunt"]] call bulwark_fnc_fobAvailable),"officer-first plan exclusion"] call _check;
BW_OFFICER_GUARDS=99;
[count ([] call bulwark_fnc_officerSettings) == 0 && {!([100] call bulwark_fnc_officerHuntAvailable)},"invalid configuration rejected"] call _check;
BW_OFFICER_GUARDS=1;
private _start = [100] call bulwark_fnc_startOfficerHunt;
[_start isEqualTo _enabled,"Specials On/Off startup gate"] call _check;
private _blockers = createGroup [east,true];
if (_enabled && {_start}) then {
    [!([100] call bulwark_fnc_startOfficerHunt),"singleton setup reservation"] call _check;
    [[{(BW_OFFICER_HUNT getOrDefault ["state",""]) == "active"},20] call _wait,"real post activation"] call _check;
    private _r = BW_OFFICER_HUNT;
    if ((_r getOrDefault ["state",""]) == "active") then {
        private _id = _r get "id";
        private _officer = _r get "officer";
        private _guards = (_r get "units") - [_officer];
        private _worker = _r get "worker";
        [count BW_OFFICER_STATUS == 5 && {BW_OFFICER_LAST_WAVE == 100},"activation publishes snapshot and cooldown"] call _check;
        [!([_id - 1,"cancelled"] call bulwark_fnc_endOfficerHunt),"stale cleanup rejected"] call _check;
        {_x allowDamage false; _x disableAI "ALL"} forEach (_r get "units");
        _r set ["nextRequest",time];
        [[{count (_r get "reinforcementGroups") == 1}] call _wait,"first reinforcement team"] call _check;
        _r set ["nextRequest",time];
        [[{count (_r get "reinforcementGroups") == 2}] call _wait,"second reinforcement team"] call _check;
        _r set ["nextRequest",time]; sleep 2;
        [count (_r get "reinforcementGroups") == 2 && {BW_INFANTRY_REMAINING == 123},"two-team cap and ordinary budget unchanged"] call _check;
        private _teams = +(_r get "reinforcementGroups");
        if !(_teams isEqualTo []) then {{deleteVehicle _x} forEach units (_teams select 0)};
        private _active = {alive _x && {side group _x in [east,resistance]}} count allUnits;
        for "_i" from _active to 39 do {private _u=_blockers createUnit ["O_Soldier_F",_site,[],0,"NONE"]; _u disableAI "ALL"; _u allowDamage false};
        _r set ["nextRequest",time];
        [[{!(BW_SPAWN_QUEUE isEqualTo [])}] call _wait,"reinforcement waits at full capacity"] call _check;
        _officer allowDamage true; _officer setDamage 1;
        [[{BW_OFFICER_STATUS isEqualTo []},3] call _wait,"officer death promptly clears objective"] call _check;
        [[{scriptDone _worker && {BW_SPAWN_QUEUE isEqualTo []}},8] call _wait,"death drains pending producer and reservation"] call _check;
        [(_guards findIf {_x getVariable ["bw_stationary",false] || {(_x getVariable ["aiMode",""]) != "rush"}}) < 0,"surviving guards regain assault flags"] call _check;
        [] call bulwark_fnc_updateOfficerHunt;
        [count BW_OFFICER_HUNT == 0 && {!([101] call bulwark_fnc_officerHuntAvailable)} &&
            {!([102] call bulwark_fnc_officerHuntAvailable)} && {[103] call bulwark_fnc_officerHuntAvailable},"completion releases singleton with two-wave cooldown"] call _check;
        {deleteVehicle _x} forEach ((waveUnits select 0) + units _blockers);
        attkWave=103;
        [[103] call bulwark_fnc_startOfficerHunt,"later wave startup"] call _check;
        [[{(BW_OFFICER_HUNT getOrDefault ["state",""]) == "active"},20] call _wait,"second post activation"] call _check;
        private _second = BW_OFFICER_HUNT;
        if ((_second getOrDefault ["state",""]) == "active") then {
            private _secondWorker = _second get "worker";
            private _survivor = _second get "officer";
            [!([_id,"cancelled"] call bulwark_fnc_endOfficerHunt),"old instance cannot close new post"] call _check;
            _second set ["deadline",time];
            [] call bulwark_fnc_updateOfficerHunt;
            [[{scriptDone _secondWorker},3] call _wait,"expiry finishes producer"] call _check;
            [alive _survivor && {(_survivor getVariable ["aiMode",""]) == "rush"} &&
                {BW_OFFICER_STATUS isEqualTo []},"expiry releases living officer without killing him"] call _check;
            [] call bulwark_fnc_updateOfficerHunt;
        };
    };
};
// Cancellation also drains failed/partial setup; never terminate a gateway waiter.
missionExtract=true;
[(BW_OFFICER_HUNT getOrDefault ["id",-1]),"testCleanup"] call bulwark_fnc_endOfficerHunt;
[{(BW_SPAWN_JOBS findIf {!scriptDone _x}) < 0},8] call _wait;
bulwark_fnc_findOfficerPost = _selector;
private _groups = [_blockers];
{_groups pushBackUnique (group _x); deleteVehicle _x} forEach ((waveUnits select 0) + units _blockers);
{if (!isNull _x && {units _x isEqualTo []}) then {deleteGroup _x}} forEach _groups;
missionNamespace setVariable ["BW_OFFICER_STATUS",[],true];
{private _v=_saved select _forEachIndex; if (_v select 0) then {missionNamespace setVariable [_x,_v select 1]} else {missionNamespace setVariable [_x,nil]}} forEach _names;
if (!isNil "BW_OFFICER_STATUS") then {publicVariable "BW_OFFICER_STATUS"};
diag_log format ["Officer Hunt tests complete: %1",_failures];
