if ((missionNamespace getVariable ["CAT_OPEN", 0]) == 2) exitWith {};
private _selection = lbCurSel 1501;
if (_selection < 0) exitWith {hint "Please select an item."};
private _id = lbValue [1501, _selection];
private _kind = switch (missionNamespace getVariable ["CAT_OPEN", 0]) do {
    case 0: {"build"}; case 1: {"support"}; case 3: {"supply"}; default {""};
};
private _recentKind = lbData [1501, _selection];
if (_recentKind in ["build", "support", "supply"]) then {_kind = _recentKind};
if (_kind == "") exitWith {};
[player, _kind, _id] remoteExecCall ["killPoints_fnc_purchase", 2];
