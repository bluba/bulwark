// Fixed server-owned actions only; never accept arbitrary SQF from the UI.
params [["_caller", objNull, [objNull]], ["_action", "", [""]], ["_special", "", [""]]];
if (!([_caller, true] call bulwark_fnc_validCaller)) exitWith {};
private _host = !isDedicated && {owner _caller == 2};
if (!_host && {admin (owner _caller) == 0}) exitWith {
    ["Debug tools are available to the host or server admins only."] remoteExecCall ["hint", _caller];
};
if !(_action in ["killEnemies", "forceSpecial"]) exitWith {};
if (missionNamespace getVariable ["BW_DEBUG_TRANSITION", false]) exitWith {};
if (_action == "forceSpecial" && {
    ! (missionNamespace getVariable ["runMissionLoop", false]) ||
    {missionNamespace getVariable ["missionExtract", false]} ||
    {missionNamespace getVariable ["missionFailure", false]} ||
    {(([] call bulwark_fnc_debugSpecials) findIf {(_x select 0) == _special}) < 0}
}) exitWith {};
private _uid = getPlayerUID _caller;
private _accepted = false;
isNil {
    private _cooldowns = missionNamespace getVariable ["BW_DEBUG_NEXT", createHashMap];
    if (time >= (_cooldowns getOrDefault [_uid, -1])) then {
        _cooldowns set [_uid, time + 2];
        missionNamespace setVariable ["BW_DEBUG_NEXT", _cooldowns];
        _accepted = true;
    };
};
if (!_accepted) exitWith {};
if (_action == "forceSpecial") exitWith {
    // Only the normal mission loop owns cancellation and the next startWave.
    BW_DEBUG_TRANSITION = true;
    BW_DEBUG_NEXT_SPECIAL = _special;
    diag_log format ["Bulwark debug: %1 (%2) requested special %3", name _caller, _uid, _special];
    ["Ending the current wave and preparing the selected special..."] remoteExecCall ["hint", _caller];
};
private _count = 0;
{
    if (alive _x && {!isPlayer _x} && {side group _x in [east, resistance]}) then {
        _x setDamage 1;
        _count = _count + 1;
    };
} forEach allUnits;
diag_log format ["Bulwark debug: %1 (%2) killed %3 current enemies", name _caller, _uid, _count];
[format ["Killed %1 enemies. Queued reinforcements may still arrive; FOB objectives remain active.", _count]] remoteExecCall ["hint", _caller];
