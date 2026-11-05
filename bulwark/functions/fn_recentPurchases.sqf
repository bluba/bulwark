// Client history contains only successful server-confirmed purchases.
// Entries are [kind, catalogue ID]; labels and prices are resolved live.
params [["_mode", "show"], ["_kind", ""], ["_id", -1], ["_slot", 0]];
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
        _recent pushBack [_entryKind, _entryId, _item select 0, _label, _item select 2, if (_entryKind == "build") then {_item select 6} else {if (_entryKind == "support") then {_item select 4} else {0}}];
    };
} forEach (missionNamespace getVariable ["BW_PURCHASE_HISTORY", []]);
if (_mode == "buy") exitWith {
    if (_slot < 0 || {_slot >= count _recent}) exitWith {hint "No previous purchase available."};
    private _entry = _recent select _slot;
    ["buy", _entry] call bulwark_fnc_shop;
};
disableSerialization;
private _display = findDisplay 9998;
if (isNull _display) exitWith {};
{
    private _button = _display displayCtrl _x;
    private _available = _forEachIndex < count _recent;
    _button ctrlEnable false;
    if (_available) then {
        private _entry = _recent select _forEachIndex;
        private _reason = [_entry] call bulwark_fnc_shopAvailability;
        _button ctrlEnable (_reason == "" && {!(missionNamespace getVariable ["BW_SHOP_PENDING", false])});
        private _name = _entry select 3;
        if (count _name > 23) then {_name = (_name select [0, 20]) + "..."};
        _button ctrlSetText format ["%1 - %2 pts", _name, _entry select 2];
        _button ctrlSetTooltip format ["Buy again: %1 - %2 points. %3", _entry select 3, _entry select 2, _reason];
    } else {
        _button ctrlSetText "No recent purchase";
        _button ctrlSetTooltip "Buy another distinct item to fill this slot.";
    };
} forEach [1615, 1616, 1617];
