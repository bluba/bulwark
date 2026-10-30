private _index = lbCurSel 1501;
if (_index >= 0 && {_index < count BULWARK_SUPPORTITEMS}) then {
    [player, "support", (BULWARK_SUPPORTITEMS select _index) select 3] remoteExecCall ["killPoints_fnc_purchase", 2];
};
