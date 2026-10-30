params [["_player", objNull, [objNull]], ["_amount", 0, [0]]];
if (!([_player, true] call bulwark_fnc_validCaller) ||
    {!finite _amount} || {_amount <= 0} || {_amount != floor _amount} ||
    {_amount > MAX_POINT_BANK_WITHDRAW_AMOUNT}) exitWith {};
private _success = false;
isNil {
    private _bank = bulwarkBox getVariable ["pointBankAmount", 0];
    if (_bank >= _amount) then {
        bulwarkBox setVariable ["pointBankAmount", _bank - _amount, true];
        _player setVariable ["killPoints", (_player getVariable ["killPoints", 0]) + _amount, true];
        _success = true;
    };
};
if (_success) then {
    [] remoteExecCall ["killPoints_fnc_updateHud", _player];
    [] remoteExecCall ["killPoints_fnc_updatePointBankAmount", 0];
} else {["Not enough points in the bank."] remoteExecCall ["hint", _player]};
