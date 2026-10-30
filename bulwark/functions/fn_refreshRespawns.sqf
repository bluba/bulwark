// Only a server job may refresh the whole roster.
if (!isServer || {isRemoteExecuted && {remoteExecutedOwner != 2}}) exitWith {};
{
    if (!alive _x) then {[_x] call bulwark_fnc_requestRespawn};
} forEach ([] call bulwark_fnc_humanPlayers);
[] remoteExecCall ["killPoints_fnc_updateHud", 0];
