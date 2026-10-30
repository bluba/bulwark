private _index = lbCurSel 1500;
if (_index >= 0 && {_index < count BULWARK_BUILDITEMS}) then {
    [player, "build", (BULWARK_BUILDITEMS select _index) select 7] remoteExecCall ["killPoints_fnc_purchase", 2];
};
