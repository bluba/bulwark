// Server requests; execution and task handles stay on the current group owner.
params ["_group", "_wave"];
if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
if !([_group] call bulwark_fnc_enemyGroupAllowed) exitWith {};
if (missionNamespace getVariable ["buildPhase", true] || {_wave != (missionNamespace getVariable ["attkWave", 0])}) exitWith {};
private _eligible = units _group select {alive _x && {isNull objectParent _x} && {!(_x getVariable ["bw_stationary", false])} && {(_x getVariable ["aiMode", ""]) != "NonCQB"}};
if (_eligible isEqualTo [] || {!(leader _group in _eligible)}) exitWith {};
_group setVariable ["bw_aiLease", diag_tickTime + 15];
private _players = ([] call bulwark_fnc_humanPlayers) select {alive _x && {lifeState _x != "INCAPACITATED"}};
if (_players isEqualTo []) exitWith {};
private _closest = _players select 0;
{if (_x distance2D leader _group < _closest distance2D leader _group) then {_closest = _x}} forEach _players;
private _base = _group getVariable ["bw_baseMode", "rush"];
private _oldMode = _group getVariable ["bw_aiMode", ""];
private _mode = _base;
private _distance = leader _group distance2D _closest;
if ((_eligible findIf {_x getVariable ["bw_suicideBomber", false]}) >= 0) then {_mode = "suicide"} else {
    if (_distance < 10 || {_oldMode == "CQB" && {_distance < 25}}) then {_mode = "CQB"};
};
private _ownerChanged = (_group getVariable ["bw_taskMachine", -1]) != clientOwner;
// CQB may finish naturally; keep its latch until the player leaves the exit radius.
if (_ownerChanged || {_mode != _oldMode}) then {
    private _oldTask = _group getVariable ["bw_taskHandle", scriptNull];
    private _oldWatch = _group getVariable ["bw_taskWatch", scriptNull];
    if (!scriptDone _oldTask) then {terminate _oldTask};
    if (!scriptDone _oldWatch) then {terminate _oldWatch};
    [_group, true, true] call lambs_wp_fnc_taskReset;
    {_x enableAI "AUTOCOMBAT"; _x forceSpeed -1; _x setUnitPos "AUTO"} forEach units _group;
    _group setBehaviour "AWARE";
    _group setCombatMode "YELLOW";
    _group setVariable ["bw_aiMode", _mode];
    _group setVariable ["bw_taskMachine", clientOwner];
    private _task = scriptNull;
    switch (_mode) do {
        case "CQB": {_task = [_group, getPosATL _closest, 50] spawn lambs_wp_fnc_taskCQB};
        case "creep": {_task = [_group, 1000] spawn lambs_wp_fnc_taskCreep};
        case "suicide": {
            {_x setVariable ["lambs_danger_disableAI", true]; _x disableAI "AUTOCOMBAT"; _x disableAI "FSM"} forEach _eligible;
            _group setBehaviour "CARELESS";
        };
        default {_task = [_group, 1000] spawn lambs_wp_fnc_taskRush};
    };
    _group setVariable ["bw_taskHandle", _task];
    private _watch = [_group, _task, _wave] spawn {
        params ["_group", "_task", "_wave"];
        waitUntil {
            sleep 1;
            !([_group] call bulwark_fnc_enemyGroupAllowed) ||
            {diag_tickTime > (_group getVariable ["bw_aiLease", 0])} ||
            {missionNamespace getVariable ["buildPhase", true]} ||
            {_wave != (missionNamespace getVariable ["attkWave", 0])} ||
            {(units _group findIf {alive _x}) < 0}
        };
        if (!scriptDone _task) then {terminate _task};
        if (local _group) then {
            // Never issue reset/movement orders during player takeover.
            if ([ _group ] call bulwark_fnc_enemyGroupAllowed) then {
                [_group, true, true] call lambs_wp_fnc_taskReset;
                {_x enableAI "AUTOCOMBAT"} forEach units _group;
            };
            _group setVariable ["bw_aiMode", ""];
            _group setVariable ["bw_taskMachine", -1];
        };
    };
    _group setVariable ["bw_taskWatch", _watch];
};
if (_mode == "suicide") then {
    {_x forceSpeed 6; _x doMove (getPosATL _closest)} forEach (_eligible select {_x getVariable ["bw_suicideBomber", false]});
};
