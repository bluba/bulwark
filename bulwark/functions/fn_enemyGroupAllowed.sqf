// Evaluate on the group's owner; remoteControlled requires unit locality.
params ["_group"];
!isNull _group && {local _group} && {side _group in [east, resistance]} &&
{(units _group findIf {isPlayer _x || {!isNull (remoteControlled _x)} || {!isNull (_x getVariable ["BIS_fnc_moduleRemoteControl_owner", objNull])}}) < 0} &&
{!(_group getVariable ["bw_scriptedMovement", false])}
