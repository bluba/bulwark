if (!hasInterface) exitWith {};
disableSerialization;
private _display = findDisplay 9998;
if (isNull _display) exitWith {};
private _personal = player getVariable ["killPoints", 0];
private _bank = if (isNil "bulwarkBox") then {0} else {bulwarkBox getVariable ["pointBankAmount", 0]};
(_display displayCtrl 1005) ctrlSetText format ["Your points: %1    |    Team bank: %2", _personal, _bank];
