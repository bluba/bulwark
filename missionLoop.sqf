if (!isServer) exitWith {};
private _downTime = "DOWN_TIME" call BIS_fnc_getParamValue;
private _additionalDownTime = "ADDITIONAL_DOWN_TIME" call BIS_fnc_getParamValue;
private _maxWaves = "MAX_WAVES" call BIS_fnc_getParamValue;
waveUnits = [[], [], []];
// Empty compatibility snapshots only; shop crates never register temporary caches.
BW_SUPPLY_CACHE = createHashMap;
BW_ENGINEERING_CACHE = createHashMap;
BW_SUPPLY_SERIAL = 0;
BW_SUPPLY_LAST_ATTEMPT = -1;
BW_ENGINEERING_LAST_ATTEMPT = -1;
missionNamespace setVariable ["BW_SUPPLY_STATUS", [], true];
missionNamespace setVariable ["BW_ENGINEERING_STATUS", [], true];
missionNamespace setVariable ["BW_SUPPLY_DELIVERY_STATUS", [], true];
missionNamespace setVariable ["BW_ENGINEERING_DELIVERY_STATUS", [], true];
BW_READY_PHASE = 0;
BW_DEBUG_NEXT_SPECIAL = "";
BW_DEBUG_FORCED_WAVE = [];
BW_DEBUG_TRANSITION = false;
BW_READY_OPEN = false;
BW_READY_VOTERS = [];
BW_PREP_DEADLINE = -1;
missionNamespace setVariable ["BW_READY_STATE", [0, false, [], 0, 1], true];
BW_ACTIVE_FOBS = [];
BW_FOB_LAST_WAVE = -1;
BW_FOB_SETUP_PENDING = false;
BW_OFFICER_SERIAL = 0;
BW_FPV_SERIAL = 0;
BW_FPV_LAST_WAVE = -1;
BW_FPV_OPERATOR = createHashMap;
BW_FPV_RESULT = [];
missionNamespace setVariable ["BW_FPV_STATUS",[],true];
[] call bulwark_fnc_fpvSites;
if ((missionNamespace getVariable ["BW_FPV_ENABLED",true]) isEqualTo true && {!(["available"] call bulwark_fnc_fpvAdapter)}) then {
    diag_log "Bulwark FPV: optional Ukraine FPV Drone addon/classes unavailable; modifier excluded";
};
BW_OFFICER_LAST_WAVE = -1;
BW_OFFICER_HUNT = createHashMap;
BW_OFFICER_RESULT = [];
missionNamespace setVariable ["BW_OFFICER_STATUS", [], true];
BW_WAVE_PROJECTILES = [];
BW_STORM_SAVED = [];
BW_STORM_TARGETS = [];
BW_STORM_JOB = scriptNull;
missionNamespace setVariable ["BW_STORM_STATE", [0, false, lightnings], true];
MIND_CONTROLLED_AI = [];
SatUnlocks = [];
publicVariable "SatUnlocks";
suicideWave = false;
runMissionLoop = true;
missionFailure = false;
missionExtract = false;
missionNamespace setVariable ["buildPhase", true, true];
[west, RESPAWN_TICKETS] call BIS_fnc_respawnTickets;
[] call bulwark_fnc_tacticalState;
[] execVM "loot\spawnLoot.sqf";
private _initialDeadline = time + 15;
waitUntil {sleep 0.2; time >= _initialDeadline || {BW_DEBUG_NEXT_SPECIAL != ""} || {missionExtract}};
private _ending = "End1";
while {runMissionLoop} do {
    if (missionExtract) exitWith {_ending = "End3"};
    // Do not create waves around an empty dedicated server.
    waitUntil {
        [] call bulwark_fnc_tacticalState;
        if (!(([] call bulwark_fnc_humanPlayers) isEqualTo []) || {missionExtract}) exitWith {true};
        sleep 1;
        false
    };
    if (missionExtract) exitWith {_ending = "End3"};
    AIstuckcheck = 0;
    AIStuckCheckArray = [];
    if (BW_DEBUG_NEXT_SPECIAL != "") then {[] call bulwark_fnc_debugAdvanceWave};
    if (missionExtract) exitWith {_ending = "End3"};
    if (!runMissionLoop) exitWith {};
    [] call bulwark_fnc_startWave;
    if (BW_DEBUG_NEXT_SPECIAL == "") then {BW_DEBUG_TRANSITION = false};
    private _defeatSince = -1;
    private _curatorPlayers = [];
    while {runMissionLoop} do {
        sleep 1;
        [] call bulwark_fnc_tacticalState;
        if (missionExtract) exitWith {};
        if (BW_DEBUG_NEXT_SPECIAL != "") exitWith {};
        private _players = [] call bulwark_fnc_humanPlayers;
        private _able = _players select {alive _x && {lifeState _x != "INCAPACITATED"}};
        private _pendingRespawn = _players findIf {!alive _x && {_x getVariable ["bw_respawnReserved", false]}};
        private _tickets = [west] call BIS_fnc_respawnTickets;
        private _defeated = !(_players isEqualTo []) && {_able isEqualTo []} && {_tickets <= 0} && {_pendingRespawn < 0};
        if (_defeated) then {
            if (_defeatSince < 0) then {_defeatSince = time};
        } else {_defeatSince = -1};
        if (_defeatSince >= 0 && {time - _defeatSince >= 45}) exitWith {missionFailure = true};
        BW_SPAWN_JOBS = BW_SPAWN_JOBS select {!scriptDone _x};
        if (BW_INFANTRY_REMAINING == 0 && {BW_SPAWN_JOBS isEqualTo []} && {BW_SPAWN_QUEUE isEqualTo []} && {(EAST countSide allUnits == 0) && {RESISTANCE countSide allUnits == 0}} &&
            {(BW_ACTIVE_FOBS findIf {alive _x}) < 0}) exitWith {};
        if (!isNil "mainZeus") then {
            private _newPlayers = _players - _curatorPlayers;
            if !(_newPlayers isEqualTo []) then {mainZeus addCuratorEditableObjects [_newPlayers, true]};
            _curatorPlayers = +_players;
        };
    };
    // Extraction takes priority over failure and the configured wave limit.
    if (missionExtract) exitWith {_ending = "End3"};
    if (missionFailure && {BW_DEBUG_NEXT_SPECIAL == ""}) exitWith {_ending = "End1"};
    if (_maxWaves > 0 && {attkWave >= _maxWaves} && {BW_DEBUG_NEXT_SPECIAL == ""}) exitWith {_ending = "End2"};
    if (BW_DEBUG_NEXT_SPECIAL == "") then {[] call bulwark_fnc_endWave};
};
runMissionLoop = false;
[(BW_FPV_OPERATOR getOrDefault ["id",-1]),"missionEnded"] call bulwark_fnc_endFpv;
[(BW_OFFICER_HUNT getOrDefault ["id", -1]), "missionEnded"] call bulwark_fnc_endOfficerHunt;
[] call bulwark_fnc_endStorm;
[] call bulwark_fnc_tacticalState;
missionNamespace setVariable ["buildPhase", true, true];
_ending call BIS_fnc_endMissionServer;
