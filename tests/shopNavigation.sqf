/* Client, disposable editor session: [] execVM "tests\shopNavigation.sqf";
   Requires initialized catalogues and no open shop. Opens/closes real controls;
   makes no purchases and restores remembered navigation state. */
if (!hasInterface || {isRemoteExecuted} || {!canSuspend} || {!isNull findDisplay 9998}) exitWith {};
disableSerialization;
private _names = ["BW_SHOP_TAB", "BW_SHOP_STATE_0", "BW_SHOP_STATE_1", "BW_SHOP_STATE_2", "BW_SHOP_STATE_3", "CAT_OPEN"];
private _saved = _names apply {[!isNil _x, missionNamespace getVariable [_x, 0]]};
private _failures = [];
private _check = {params ["_ok", "_label"]; if (!_ok) then {_failures pushBack _label}};
[] call bulwark_fnc_purchaseGuiNew;
private _d = findDisplay 9998;
[!isNull _d, "shop opens"] call _check;
if (!isNull _d) then {
    ["tab", 0] call bulwark_fnc_shop;
    (_d displayCtrl 1401) ctrlSetText "";
    (_d displayCtrl 1500) lbSetCurSel 1;
    ["list"] call bulwark_fnc_shop;
    private _rows = _d getVariable ["bw_rows", []];
    [count _rows > 0, "building category has items"] call _check;
    if (count _rows > 0) then {
        (_d displayCtrl 1501) lbSetCurSel ((count _rows - 1) min 2);
        private _entry = +(_d getVariable ["bw_selected", []]);
        ["tab", 3] call bulwark_fnc_shop;
        ["tab", 0] call bulwark_fnc_shop;
        [(_d getVariable ["bw_selected", []]) isEqualTo _entry, "tab switch restores selected catalogue item"] call _check;
        closeDialog 0;
        [] call bulwark_fnc_purchaseGuiNew;
        _d = findDisplay 9998;
        [(_d getVariable ["bw_selected", []]) isEqualTo _entry, "reopen restores selected catalogue item"] call _check;
    };
    private _catalogue = _d getVariable ["bw_catalogue", []];
    private _supply = _catalogue findIf {(_x select 0) == "supply"};
    if (_supply >= 0) then {
        private _entry = _catalogue select _supply;
        (_d displayCtrl 1401) ctrlSetText (_entry select 3);
        ["list"] call bulwark_fnc_shop;
        [(_d getVariable ["bw_rows", []]) findIf {(_x select [0,2]) isEqualTo (_entry select [0,2])} >= 0, "Build search finds supply by stable kind and ID"] call _check;
    };
    (_d displayCtrl 1401) ctrlSetText "__no_such_bulwark_item__";
    ["list"] call bulwark_fnc_shop;
    [lbSize (_d displayCtrl 1501) == 0 && {!ctrlEnabled (_d displayCtrl 1602)}, "empty search disables purchase"] call _check;
    {
        ["tab", _x] call bulwark_fnc_shop;
        [ctrlShown (_d displayCtrl 1615) && {ctrlShown (_d displayCtrl 1616)} && {ctrlShown (_d displayCtrl 1617)}, format ["recent buttons visible on tab %1", _x]] call _check;
    } forEach [0,1,3,2];
    closeDialog 0;
};
{
    private _state = _saved select _forEachIndex;
    missionNamespace setVariable [_x, if (_state select 0) then {_state select 1} else {nil}];
} forEach _names;
diag_log format ["SHOP NAVIGATION failures: %1", _failures];
