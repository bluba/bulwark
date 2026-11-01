// Run during an active combat wave, with the mission functions loaded:
// [] execVM "tests\vehicleTicketEmptyPlan.sqf";
// The empty plan must not sleep or spawn anything. No globals are changed.
if (!isServer || {!canSuspend}) exitWith {};
if !([attkWave] call bulwark_fnc_waveActive) exitWith {diag_log "Empty-plan regression requires an active wave"};
private _plan = createHashMapFromArray [["entries",[]],["budget",0],["unused",0]];
private _started = diag_tickTime;
[attkWave,_plan,false] call compile preprocessFileLineNumbers "hostiles\vehicleSchedule.sqf";
private _elapsed = diag_tickTime - _started;
if (_elapsed > 2 || {!((_plan getOrDefault ["outcomes",["missing"]]) isEqualTo [])}) then {
 throw format ["Empty vehicle plan blocked completion: %1 seconds",_elapsed];
};
diag_log "PASS: empty vehicle plan returns without arrival delays";
