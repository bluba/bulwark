if ((missionNamespace getVariable ["CAT_OPEN", 0]) == 2) exitWith {};
private _selection = lbCurSel 1501;
if (_selection < 0) exitWith {hint "Please select an item."};
private _id = lbValue [1501, _selection];
private _kind = if (_id >= 8001) then {"support"} else {"build"};
[player, _kind, _id] remoteExecCall ["killPoints_fnc_purchase", 2];
