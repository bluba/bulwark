params [["_player", objNull, [objNull]], ["_points", -1, [0]]];
if (!([_player] call bulwark_fnc_validCaller) || {!finite _points} || {_points < 0}) exitWith {false};
private _paid = false;
isNil {
    private _balance = _player getVariable ["killPoints", 0];
    if (_balance >= _points) then {
        _player setVariable ["killPoints", _balance - _points, true];
        _paid = true;
    };
};
if (_paid) then {[] remoteExecCall ["killPoints_fnc_updateHud", _player]};
_paid
