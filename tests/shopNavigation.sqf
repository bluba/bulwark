/* Client, disposable editor session: [] execVM "tests\shopNavigation.sqf";
   Requires initialized catalogues and no open shop. Opens/closes real controls;
   makes no purchases and restores remembered navigation state and profile
   favourites. Run to completion: favourite tests temporarily write the profile. */
if (!hasInterface || {isRemoteExecuted} || {!canSuspend} || {!isNull findDisplay 9998}) exitWith {};
disableSerialization;
private _names = ["BW_SHOP_TAB", "BW_SHOP_STATE_0", "BW_SHOP_STATE_1", "BW_SHOP_STATE_2", "BW_SHOP_STATE_3", "BW_SHOP_STATE_4", "BW_SHOP_STATE_5", "BW_SHOP_STATE_6", "CAT_OPEN"];
private _saved = _names apply {[!isNil _x, missionNamespace getVariable [_x, 0]]};
private _hadFavourites = !isNil {profileNamespace getVariable "BW_SHOP_FAVOURITES_V1"};
private _savedFavourites = profileNamespace getVariable ["BW_SHOP_FAVOURITES_V1", []];
profileNamespace setVariable ["BW_SHOP_FAVOURITES_V1", []];
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
    } forEach [0,1,3,4,5,6,2];
    {
        _x params ["_tab", "_category"];
        ["tab", _tab] call bulwark_fnc_shop;
        (_d displayCtrl 1401) ctrlSetText "";
        (_d displayCtrl 1500) lbSetCurSel 0;
        ["list"] call bulwark_fnc_shop;
        private _rows = _d getVariable ["bw_rows", []];
        [count _rows > 0 && {_rows findIf {(_x select 0) != "build" || {(_x select 5) != _category}} < 0}, format ["tab %1 contains only its original build catalogue category", _tab]] call _check;
    } forEach [[4,6],[5,7]];
    ["tab", 0] call bulwark_fnc_shop;
    (_d displayCtrl 1401) ctrlSetText "";
    (_d displayCtrl 1500) lbSetCurSel 0;
    ["list"] call bulwark_fnc_shop;
    [(_d getVariable ["bw_rows", []]) findIf {(_x select 5) in [6,7,10]} < 0, "Build excludes vehicles, allies and developer entries"] call _check;
    // Removed category rows must not shift the remaining category IDs.
    {
        _x params ["_row", "_category"];
        (_d displayCtrl 1500) lbSetCurSel _row;
        private _rows = _d getVariable ["bw_rows", []];
        [count _rows > 0 && {_rows findIf {(_x select 5) != _category} < 0}, format ["Build row %1 still maps to category %2", _row, _category]] call _check;
    } forEach [[7,8],[8,9]];
    ["tab", 4] call bulwark_fnc_shop;
    private _vehicle = +(_d getVariable ["bw_selected", []]);
    if !(_vehicle isEqualTo []) then {
        private _key = [_vehicle select 0, _vehicle select 1, _vehicle select 4];
        ["favourite"] call bulwark_fnc_shop;
        [_key in (profileNamespace getVariable ["BW_SHOP_FAVOURITES_V1", []]), "save favourite persists the original kind, ID and class"] call _check;
        ["tab", 6] call bulwark_fnc_shop;
        (_d displayCtrl 1401) ctrlSetText "";
        (_d displayCtrl 1500) lbSetCurSel 0;
        ["list"] call bulwark_fnc_shop;
        [(_d getVariable ["bw_rows", []]) isEqualTo [_vehicle], "Favourites resolves the original vehicle purchase entry"] call _check;
        closeDialog 0;
        [] call bulwark_fnc_purchaseGuiNew;
        _d = findDisplay 9998;
        [(_d getVariable ["bw_rows", []]) isEqualTo [_vehicle], "favourite survives reopen and profile reload"] call _check;
        (_d displayCtrl 1401) ctrlSetText "__no_such_favourite__";
        ["list"] call bulwark_fnc_shop;
        [lbSize (_d displayCtrl 1501) == 0 && {!ctrlEnabled (_d displayCtrl 1621)}, "empty favourite search disables toggle"] call _check;
        (_d displayCtrl 1401) ctrlSetText "";
        (_d displayCtrl 1500) lbSetCurSel 3;
        ["list"] call bulwark_fnc_shop;
        [lbSize (_d displayCtrl 1501) == 0, "Allies favourite filter excludes a vehicle"] call _check;
        (_d displayCtrl 1500) lbSetCurSel 2;
        [(_d getVariable ["bw_rows", []]) isEqualTo [_vehicle], "Vehicles favourite filter includes the vehicle"] call _check;
        ["favourite"] call bulwark_fnc_shop;
        [lbSize (_d displayCtrl 1501) == 0 && {!ctrlEnabled (_d displayCtrl 1602)} && {!( _key in (profileNamespace getVariable ["BW_SHOP_FAVOURITES_V1", []]))}, "removing last favourite clears selection and disables purchase"] call _check;
    };
    closeDialog 0;
};
{
    private _state = _saved select _forEachIndex;
    missionNamespace setVariable [_x, if (_state select 0) then {_state select 1} else {nil}];
} forEach _names;
profileNamespace setVariable ["BW_SHOP_FAVOURITES_V1", if (_hadFavourites) then {_savedFavourites} else {nil}];
saveProfileNamespace;
diag_log format ["SHOP NAVIGATION failures: %1", _failures];
