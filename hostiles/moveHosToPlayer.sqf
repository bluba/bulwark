if (!isServer || {isNil "waveUnits"}) exitWith {};
if !([attkWave] call bulwark_fnc_waveActive) exitWith {};

{
    private _members = units _x;
// Register unscored Zeus enemies from the same group snapshot used below.
{
    if (alive _x && {side group _x in [east, resistance]} && {!isPlayer _x} && {isNil {_x getVariable "killPointMulti"}}) then {
        _x addEventHandler ["Hit", killPoints_fnc_hit];
        _x addEventHandler ["Killed", killPoints_fnc_killed];
        _x setVariable ["points", []];
        _x setVariable ["killPointMulti", 2, true];
        (waveUnits select 0) pushBackUnique _x;
    };
} forEach _members;
    if (side _x in [east, resistance] && {!(_x getVariable ["bw_scriptedMovement", false])} && {(_members findIf {isPlayer _x}) < 0}) then {
        if (local _x) then {[_x, attkWave] call bulwark_fnc_controlEnemyGroup} else {
            [_x, attkWave] remoteExecCall ["bulwark_fnc_controlEnemyGroup", groupOwner _x];
        };
    };
} forEach allGroups;
