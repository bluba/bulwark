params [["_player", objNull, [objNull]]];
if (!([_player, true] call bulwark_fnc_validCaller)) exitWith {};
if ([_player, 200] call killPoints_fnc_spend) then {
    [_player, 0] remoteExecCall ["setDamage", _player];
};
