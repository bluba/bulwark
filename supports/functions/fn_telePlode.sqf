/**
*  fn_telePlode
*
*  teleports player back to Bulwark Box and creates an explosion where they were
*
*  Domain: Server
**/

_player = _this select 0;
_explosionPos = position _player;

private _destination = [bulwarkBox, _player] call bulwark_fnc_findPlaceAround;
if (_destination isEqualTo []) exitWith {
    ["No clear ground near the Bulwark. Try again after it moves."] remoteExecCall ["hint", _player];
    [_player, "telePlode"] remoteExecCall ["BIS_fnc_addCommMenuItem", _player];
};
_player setPosASL _destination;
["teleport"] remoteExec ["playSound", _player];
sleep 0.5;
_scriptedCharge = "DemoCharge_Remote_Ammo_Scripted" createVehicle _explosionPos;
_scriptedCharge setDamage 1;
