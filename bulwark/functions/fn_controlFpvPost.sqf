params ["_group","_wave","_id",["_release",false]];
if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
if (isNull _group || {!local _group} || {(_group getVariable ["bw_fpvId",-1]) != _id}) exitWith {};
if ((units _group findIf {isPlayer _x || {!isNull remoteControlled _x}}) >= 0) exitWith {};
if (_release) exitWith {
    {_x enableAI "PATH"} forEach units _group;
    [_group,_wave] call bulwark_fnc_controlEnemyGroup;
};
if (!(_group getVariable ["bw_fpvActive",false]) || {missionNamespace getVariable ["buildPhase",true]} ||
    {_wave != (missionNamespace getVariable ["attkWave",-1])}) exitWith {};
// A local guard post: stay at the prepared site, but turn, aim and fire normally.
{private _h = _group getVariable [_x,scriptNull]; if (!scriptDone _h) then {terminate _h}} forEach ["bw_taskHandle","bw_taskWatch"];
{_x disableAI "PATH"; doStop _x} forEach units _group;
_group setBehaviour "AWARE";
_group setCombatMode "RED";
