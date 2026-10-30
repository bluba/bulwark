params ["_object", "_buyer", "_radius", "_direction"];
if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
if (!hasInterface || {player != _buyer} || {isNull _object}) exitWith {};
closeDialog 0;
// The server has reserved the holding slot; pickup performs the local attachment.
player setVariable ["buildItemHeld", false, true];
[_object, player, [0, _radius + 1.5, 0.02], _direction] call build_fnc_pickup;
