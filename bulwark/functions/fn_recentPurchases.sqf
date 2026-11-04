// Client history contains only successful server-confirmed purchases.
// Entries are [kind, catalogue ID]; labels and prices are resolved live.
params [["_mode", "show"], ["_kind", ""], ["_id", -1]];
if (!hasInterface) exitWith {};
if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
if (_mode == "record") exitWith {
    private _history = missionNamespace getVariable ["BW_PURCHASE_HISTORY", []];
    private _entry = [_kind, _id];
    _history = _history select {!(_x isEqualTo _entry)};
    _history insert [0, [_entry]];
    _history resize ((count _history) min (1 max (missionNamespace getVariable ["BW_PURCHASE_HISTORY_LIMIT", 10])));
    missionNamespace setVariable ["BW_PURCHASE_HISTORY", _history];
    if (!isNull findDisplay 9998) then {[] call bulwark_fnc_recentPurchases};
};
private _recent = [];
{
    _x params ["_entryKind", "_entryId"];
    private _catalogue = switch (_entryKind) do {
        case "build": {missionNamespace getVariable ["BULWARK_BUILDITEMS", []]};
        case "supply": {missionNamespace getVariable ["BULWARK_SUPPLYITEMS", []]};
        default {missionNamespace getVariable ["BULWARK_SUPPORTITEMS", []]};
    };
    private _field = if (_entryKind == "build") then {7} else {3};
    private _index = _catalogue findIf {(_x select _field) == _entryId};
    if (_index >= 0) then {
        private _item = _catalogue select _index;
        private _label = _item select 1;
        if (_entryKind == "supply") then {_label = localize _label};
        _recent pushBack [_entryKind, _entryId, _item select 0, _label];
    };
} forEach (missionNamespace getVariable ["BW_PURCHASE_HISTORY", []]);
if (_mode == "buy") exitWith {
    if (_recent isEqualTo []) exitWith {hint "No previous purchase available."};
    private _entry = _recent select 0;
    [player, _entry select 0, _entry select 1] remoteExecCall ["killPoints_fnc_purchase", 2];
};
disableSerialization;
private _display = findDisplay 9998;
if (isNull _display) exitWith {};
private _button = _display displayCtrl 1615;
_button ctrlEnable !(_recent isEqualTo []);
_button ctrlSetText (if (_recent isEqualTo []) then {"BUY LAST ITEM AGAIN"} else {
    format ["BUY AGAIN: %1", (_recent select 0) select 3]
});
_button ctrlSetTooltip (if (_recent isEqualTo []) then {"Buy an item to enable repeat purchase."} else {
    format ["%1 — %2 points", (_recent select 0) select 3, (_recent select 0) select 2]
});
if ((missionNamespace getVariable ["CAT_OPEN", 0]) != 0 || {lbCurSel (_display displayCtrl 1500) >= 0}) exitWith {};
private _list = _display displayCtrl 1501;
lbClear _list;
_list ctrlEnable true;
{
    private _row = _list lbAdd format ["Buy again: %1 — %2", _x select 3, _x select 2];
    _list lbSetValue [_row, _x select 1];
    _list lbSetData [_row, _x select 0];
} forEach (_recent select [0, 1 max (missionNamespace getVariable ["BW_RECENT_PURCHASE_COUNT", 1])]);
if (_recent isEqualTo []) then {_list lbAdd "Select an item category to begin."; _list ctrlEnable false};
