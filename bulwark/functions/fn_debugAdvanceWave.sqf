// Called only by the mission loop, never directly from the debug RPC.
if (!isServer || {isRemoteExecuted} || {!canSuspend}) exitWith {false};
private _type = missionNamespace getVariable ["BW_DEBUG_NEXT_SPECIAL", ""];
if ((([] call bulwark_fnc_debugSpecials) findIf {(_x select 0) == _type}) < 0) exitWith {false};
private _wave = attkWave;
missionNamespace setVariable ["buildPhase", true, true];
BW_READY_OPEN = false;
isNil {[] call bulwark_fnc_updateReadyVote};
[] call bulwark_fnc_endStorm;
[(missionNamespace getVariable ["BW_FPV_OPERATOR",createHashMap]) getOrDefault ["id",-1],"debugRestart"] call bulwark_fnc_endFpv;
[(missionNamespace getVariable ["BW_OFFICER_HUNT", createHashMap]) getOrDefault ["id", -1], "debugRestart"] call bulwark_fnc_endOfficerHunt;
[(BW_SUPPLY_CACHE getOrDefault ["id", -1]), "debugRestart"] call loot_fnc_endSupplyCache;
[(BW_ENGINEERING_CACHE getOrDefault ["id", -1]), "debugRestart", "engineering"] call loot_fnc_endSupplyCache;
{deleteVehicle _x} forEach BW_WAVE_PROJECTILES;
BW_WAVE_PROJECTILES = [];
{deleteVehicle _x} forEach BW_ACTIVE_FOBS;
private _hostiles = allUnits select {side group _x in [east, resistance] && {!isPlayer _x}};
private _vehicles = vehicles select {
    ((_x getVariable ["bw_hostileWave", -1]) == _wave ||
        {(crew _x findIf {side group _x in [east, resistance]}) >= 0}) &&
    {(crew _x findIf {isPlayer _x || {!(side group _x in [east, resistance])}}) < 0}
};
// Deletion avoids bomber death explosions during the administrative transition.
{deleteVehicle _x} forEach _hostiles;
{deleteVehicle _x} forEach _vehicles;
deleteMarker (format ["BulwarkBonus_%1", _wave]);
BW_INFANTRY_REMAINING = 0;
// Let capacity helpers finish and release their own reservations. Do not kill
// producers mid-creation or reset shared queues while an old helper can return.
private _warnAt = time + 20;
waitUntil {
    sleep 0.2;
    // A script error may leave a ticket behind. Only discard tickets whose
    // recorded producer has actually finished; live helpers must release theirs.
    BW_SPAWN_QUEUE = BW_SPAWN_QUEUE select {count _x < 5 || {!scriptDone (_x select 4)}};
    [] call bulwark_fnc_updateOfficerHunt;
    if (time >= _warnAt) then {
        diag_log format ["Bulwark debug: waiting for wave %1 producers/queue to drain", _wave];
        _warnAt = time + 20;
    };
    missionExtract || {!runMissionLoop} ||
    {(BW_SPAWN_JOBS findIf {!scriptDone _x}) < 0 && {BW_SPAWN_QUEUE isEqualTo []}}
};
if (missionExtract || {!runMissionLoop}) exitWith {false};
// Persistent effects have a captured old wave. Give their short cleanup ticks
// time to retire before making the new wave active.
sleep 1;
[] call bulwark_fnc_updateOfficerHunt;
BW_ACTIVE_FOBS = [];
BW_FOB_SETUP_PENDING = false;
BW_SPAWN_JOBS = [];
BW_DEBUG_FORCED_WAVE = [_wave + 1, _type];
BW_DEBUG_NEXT_SPECIAL = "";
BW_PREP_DEADLINE = time;
diag_log format ["Bulwark debug: advancing wave %1 -> %2, selected %3", _wave, _wave + 1, _type];
true
