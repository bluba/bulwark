if (!isServer || {isNil "waveUnits"}) exitWith {};
if !([attkWave] call bulwark_fnc_waveActive) exitWith {};
// Register unscored Zeus enemies without assigning a second movement controller.
{
    if (alive _x && {side group _x in [east, resistance]} && {!isPlayer _x} && {isNil {_x getVariable "killPointMulti"}}) then {
        _x addEventHandler ["Hit", killPoints_fnc_hit];
        _x addEventHandler ["Killed", killPoints_fnc_killed];
        _x setVariable ["points", []];
        _x setVariable ["killPointMulti", 2, true];
        (waveUnits select 0) pushBackUnique _x;
    };
} forEach allUnits;
{
    if (side _x in [east, resistance] && {!(_x getVariable ["bw_scriptedMovement", false])} && {(units _x findIf {isPlayer _x}) < 0}) then {
        if (local _x) then {[_x, attkWave] call bulwark_fnc_controlEnemyGroup} else {
            [_x, attkWave] remoteExecCall ["bulwark_fnc_controlEnemyGroup", groupOwner _x];
        };
    };
} forEach allGroups;
