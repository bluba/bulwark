// Client-only shop state. Catalogue IDs, never filtered row indices, identify purchases.
params [["_mode", "refresh"], ["_value", 0]];
if (!hasInterface || {isRemoteExecuted}) exitWith {};
disableSerialization;
private _display = findDisplay 9998;
if (isNull _display) exitWith {};
private _categories = _display displayCtrl 1500;
private _items = _display displayCtrl 1501;
switch (_mode) do {
    case "init": {
        private _catalogue = [];
        {
            _catalogue pushBack ["build", _x select 7, _x select 0, _x select 1, _x select 2, _x select 6];
        } forEach BULWARK_BUILDITEMS;
        {
            _catalogue pushBack ["support", _x select 3, _x select 0, _x select 1, _x select 2, _x select 4];
        } forEach BULWARK_SUPPORTITEMS;
        {
            _catalogue pushBack ["supply", _x select 3, _x select 0, localize (_x select 1), _x select 2, 0];
        } forEach (missionNamespace getVariable ["BULWARK_SUPPLYITEMS", []]);
        _display setVariable ["bw_catalogue", _catalogue];
        _categories ctrlAddEventHandler ["LBSelChanged", {['category'] call bulwark_fnc_shop}];
        _items ctrlAddEventHandler ["LBSelChanged", {['select'] call bulwark_fnc_shop}];
        (_display displayCtrl 1401) ctrlAddEventHandler ["KeyUp", {
            private _d = ctrlParent (_this select 0);
            private _query = ctrlText (_this select 0);
            if (_query != (_d getVariable ["bw_query", ""])) then {
                _d setVariable ["bw_query", _query];
                ['list'] call bulwark_fnc_shop;
            };
        }];
        ['tab', missionNamespace getVariable ["BW_SHOP_TAB", 0]] call bulwark_fnc_shop;
        [_display] spawn {
            disableSerialization;
            params ["_d"];
            while {!isNull _d && {findDisplay 9998 isEqualTo _d}} do {
                private _query = ctrlText (_d displayCtrl 1401);
                if (_query != (_d getVariable ["bw_query", ""])) then {
                    _d setVariable ["bw_query", _query];
                    ['list'] call bulwark_fnc_shop;
                };
                ['refresh'] call bulwark_fnc_shop;
                uiSleep 0.25;
            };
        };
    };
    case "save": {
        private _tab = _display getVariable ["bw_tab", -1];
        if (_tab < 0) exitWith {};
        private _entry = _display getVariable ["bw_selected", []];
        missionNamespace setVariable [format ["BW_SHOP_STATE_%1", _tab], [lbCurSel _categories, ctrlText (_display displayCtrl 1401), _entry select [0, 2]]];
        missionNamespace setVariable ["BW_SHOP_TAB", _tab];
    };
    case "tab": {
        ['save'] call bulwark_fnc_shop;
        private _admin = isServer || {serverCommandAvailable "#kick"};
        if !(_value in [0, 1, 2, 3]) then {_value = 0};
        if (_value == 2 && {!_admin}) then {_value = 0};
        CAT_OPEN = _value;
        _display setVariable ["bw_tab", _value];
        _display setVariable ["bw_populating", true];
        private _debug = _value == 2;
        {(_display displayCtrl _x) ctrlShow (!_debug)} forEach [1500,1501,1401,1606,1200,1020,1602,1022,1024];
        {(_display displayCtrl _x) ctrlShow _debug} forEach [1611,1010,1510,1612,1613];
        (_display displayCtrl 1610) ctrlShow _admin;
        {
            (_display displayCtrl (_x select 0)) ctrlSetBackgroundColor (if (_value == (_x select 1)) then {[0.12,0.35,0.45,1]} else {[0.15,0.15,0.15,1]});
        } forEach [[1600,0],[1601,1],[1614,3],[1610,2]];
        private _labels = switch (_value) do {
            case 0: {["All build items", "Building elements", "Bunkers", "Walls & fences", "Ramps & stairs", "Barricades", "Weapon emplacements", "Vehicles", "Allies", "Containers", "Static defences"]};
            case 1: {["All support items", "Extra lives", "Supports"]};
            case 3: {["Supply crates"]};
            default {[]};
        };
        lbClear _categories;
        {_categories lbAdd _x} forEach _labels;
        private _state = missionNamespace getVariable [format ["BW_SHOP_STATE_%1", _value], [0, "", []]];
        private _cat = (_state select 0) max 0 min ((count _labels - 1) max 0);
        _categories lbSetCurSel _cat;
        (_display displayCtrl 1401) ctrlSetText (_state select 1);
        _display setVariable ["bw_query", _state select 1];
        _display setVariable ["bw_restore", _state select 2];
        _display setVariable ["bw_populating", false];
        if (_debug) then {
            private _list = _display displayCtrl 1510;
            if (lbSize _list == 0) then {
                {private _row = _list lbAdd (_x select 1); _list lbSetData [_row, _x select 0]} forEach ([] call bulwark_fnc_debugSpecials);
                _list lbSetCurSel 0;
            };
        };
        ['list'] call bulwark_fnc_shop;
    };
    case "category": {
        if (_display getVariable ["bw_populating", false]) exitWith {};
        ['list'] call bulwark_fnc_shop;
    };
    case "list": {
        private _tab = _display getVariable ["bw_tab", 0];
        private _query = toLower ctrlText (_display displayCtrl 1401);
        private _cat = lbCurSel _categories;
        private _kind = switch (_tab) do {case 0: {"build"}; case 1: {"support"}; case 3: {"supply"}; default {""}};
        private _selected = _display getVariable ["bw_restore", (_display getVariable ["bw_selected", []]) select [0, 2]];
        _display setVariable ["bw_restore", nil];
        private _rows = (_display getVariable ["bw_catalogue", []]) select {
            (_x select 0 != "build" || {_x select 5 != 10}) && {_tab != 2} && {
                if (_query != "") then {toLower (_x select 3) find _query >= 0}
                else {(_x select 0) == _kind && {_cat <= 0 || {_tab == 3} || {(_x select 5) == _cat - 1}}}
            }
        };
        _display setVariable ["bw_populating", true];
        lbClear _items;
        {
            private _label = _x select 3;
            if (_query != "") then {_label = format ["%1 [%2]", _label, _x select 0]};
            private _row = _items lbAdd (if (count _label > 36) then {(_label select [0, 33]) + "..."} else {_label});
            _items lbSetTooltip [_row, format ["%1 - %2 points", _label, _x select 2]];
            _items lbSetTextRight [_row, format ["%1 pts", _x select 2]];
        } forEach _rows;
        _display setVariable ["bw_rows", _rows];
        private _index = _rows findIf {(_x select [0, 2]) isEqualTo _selected};
        if (_index < 0 && {count _rows > 0}) then {_index = 0};
        _items lbSetCurSel _index;
        _display setVariable ["bw_populating", false];
        (_display displayCtrl 1022) ctrlSetText (if (_query == "") then {"Items"} else {format ["Search results across all tabs: %1", count _rows]});
        ['select'] call bulwark_fnc_shop;
    };
    case "select": {
        if (_display getVariable ["bw_populating", false]) exitWith {};
        private _rows = _display getVariable ["bw_rows", []];
        private _index = lbCurSel _items;
        private _entry = if (_index >= 0 && {_index < count _rows}) then {_rows select _index} else {[]};
        _display setVariable ["bw_selected", _entry];
        private _picture = "#(argb,8,8,3)color(0,0,0,0)";
        if !(_entry isEqualTo []) then {
            private _class = _entry select 4;
            if (_entry select 0 == "supply") then {
                private _keys = [_class] call loot_fnc_supplyFamily;
                if !(_keys isEqualTo []) then {_class = missionNamespace getVariable [_keys select 6, "Box_NATO_Equip_F"]};
            };
            if (_entry select 0 != "support") then {_picture = getText (configFile >> "CfgVehicles" >> _class >> "editorPreview")};
        };
        (_display displayCtrl 1200) ctrlSetText _picture;
        ['save'] call bulwark_fnc_shop;
        ['refresh'] call bulwark_fnc_shop;
    };
    case "buy": {
        if (missionNamespace getVariable ["BW_SHOP_PENDING", false]) exitWith {};
        private _entry = if (_value isEqualType []) then {_value} else {_display getVariable ["bw_selected", []]};
        if (_entry isEqualTo []) exitWith {};
        private _reason = [_entry] call bulwark_fnc_shopAvailability;
        if (_reason != "") exitWith {missionNamespace setVariable ["BW_SHOP_MESSAGE", _reason]; ["refresh"] call bulwark_fnc_shop};
        missionNamespace setVariable ["BW_SHOP_PENDING", true];
        missionNamespace setVariable ["BW_SHOP_PENDING_AT", diag_tickTime];
        missionNamespace setVariable ["BW_SHOP_MESSAGE", format ["Purchasing %1...", _entry select 3]];
        [player, _entry select 0, _entry select 1] remoteExecCall ["killPoints_fnc_purchase", 2];
        ['refresh'] call bulwark_fnc_shop;
    };
    case "refresh": {
        [] call killPoints_fnc_updatePointBankAmount;
        private _pending = missionNamespace getVariable ["BW_SHOP_PENDING", false];
        if (_pending && {diag_tickTime - (missionNamespace getVariable ["BW_SHOP_PENDING_AT", diag_tickTime]) > 20}) then {
            missionNamespace setVariable ["BW_SHOP_MESSAGE", "Still awaiting server confirmation. Do not retry the purchase."];
        };
        (_display displayCtrl 1021) ctrlSetText (missionNamespace getVariable ["BW_SHOP_MESSAGE", ""]);
        private _entry = _display getVariable ["bw_selected", []];
        private _reason = [_entry] call bulwark_fnc_shopAvailability;
        private _button = _display displayCtrl 1602;
        _button ctrlEnable (!_pending && {_reason == ""});
        _button ctrlSetTooltip _reason;
        private _detail = "No matching items. Try another category or clear search.";
        _button ctrlSetText "Select an item";
        if !(_entry isEqualTo []) then {
            _entry params ["_kind", "_id", "_price", "_label"];
            private _action = if (_kind == "support") then {if (_entry select 5 == 0) then {"Buy extra lives"} else {"Buy support"}} else {"Buy & place"};
            _button ctrlSetText format ["%1 - %2 pts", _action, _price];
            private _outcome = if (_kind == "support") then {if (_entry select 5 == 0) then {"Adds team respawn tickets."} else {"Adds an action to your support menu."}} else {"Closes the shop and picks up the item for placement."};
            if (_kind == "supply") then {_outcome = "Pick up and place a stocked supply crate. Moving it does not refill it."};
            _detail = [_label, _outcome, format ["Cost: %1 points", _price], format ["Points remaining: %1", ((player getVariable ["killPoints", 0]) - _price) max 0], _reason] joinString (toString [10]);
        };
        (_display displayCtrl 1020) ctrlSetText _detail;
        (_display displayCtrl 1020) ctrlSetTooltip _detail;
        [] call bulwark_fnc_recentPurchases;
    };
};
