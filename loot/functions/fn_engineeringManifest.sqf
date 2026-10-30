// Called once by the server worker. Explicit inventory pools, never live explosives.
private _mode = missionNamespace getVariable ["LOOT_WHITELIST_MODE", 0];
private _blacklist = missionNamespace getVariable ["LOOT_BLACKLIST", []];
private _items = missionNamespace getVariable ["LOOT_WHITELIST_ITEM", []];
private _magazines = missionNamespace getVariable ["LOOT_WHITELIST_EXPLOSIVE", []];
if (!(_mode in [0,1,2]) || {!(_blacklist isEqualType [])} || {!(_items isEqualType [])} || {!(_magazines isEqualType [])}) exitWith {[]};
private _ap = ["APERSMine_Range_Mag", "APERSBoundingMine_Range_Mag", "APERSTripMine_Wire_Mag"];
private _at = ["ATMine_Range_Mag", "SLAMDirectionalMine_Wire_Mag"];
private _frag = ["HandGrenade", "MiniGrenade"];
// [pool config, range config, default pool, default range, hard cap, cargo tag]
private _definitions = [
    ["BW_ENGINEERING_AP_POOL", "BW_ENGINEERING_AP_COUNT", _ap, [1,2], 2, "magazine"],
    ["BW_ENGINEERING_AT_POOL", "BW_ENGINEERING_AT_COUNT", _at, [1,2], 2, "magazine"],
    ["BW_ENGINEERING_GRENADE_POOL", "BW_ENGINEERING_GRENADE_COUNT", _frag, [1,3], 3, "magazine"],
    ["BW_ENGINEERING_SMOKE_POOL", "", ["SmokeShell"], [2,2], 2, "magazine"],
    ["BW_ENGINEERING_TOOLS", "", ["MineDetector", "ToolKit"], [1,1], 1, "item"]
];
private _resolved = [];
private _valid = true;
{
    _x params ["_poolKey", "_rangeKey", "_allowed", "_defaultRange", "_cap", "_tag"];
    private _pool = missionNamespace getVariable [_poolKey, _allowed];
    private _range = if (_rangeKey == "") then {_defaultRange} else {missionNamespace getVariable [_rangeKey, _defaultRange]};
    if (!(_pool isEqualType []) || {!(_range isEqualType [])} || {count _range != 2} ||
        {(_range findIf {!(_x isEqualType 0) || {!finite _x} || {_x != floor _x} || {_x < 0} || {_x > _cap}}) >= 0} ||
        {(_range select 0) > (_range select 1)} || {(_pool findIf {!(_x isEqualType "")}) >= 0}) exitWith {_valid = false};
    _pool = (_pool arrayIntersect _allowed) select {
        private _root = if (_tag == "item") then {"CfgWeapons"} else {"CfgMagazines"};
        private _cfg = configFile >> _root >> _x;
        isClass _cfg && {!(_x in _blacklist)} &&
        {_mode != 1 || {_x in (if (_tag == "item") then {_items} else {_magazines})}} &&
        {if (_tag == "item") then {isClass (_cfg >> "ItemInfo")} else {
            getNumber (_cfg >> "count") > 0 && {isClass (configFile >> "CfgAmmo" >> getText (_cfg >> "ammo"))}
        }}
    };
    _resolved pushBack [_pool, _range, _tag];
} forEach _definitions;
if (!_valid) exitWith {[]};
private _manifest = [];
private _mineCount = 0;
{
    _x params ["_pool", "_range", "_tag"];
    if !(_pool isEqualTo []) then {
        private _classes = [];
        if (_tag == "item") then {
            _classes = +_pool; // One of EACH approved tool, not one randomly selected tool.
        } else {
            private _quantity = (_range select 0) + floor random ((_range select 1) - (_range select 0) + 1);
            for "_i" from 1 to _quantity do {_classes pushBack (selectRandom _pool)};
        };
        if (_forEachIndex < 2) then {_mineCount = _mineCount + count _classes};
        {
            private _class = _x;
            private _index = _manifest findIf {(_x select 0) == _tag && {(_x select 1) == _class}};
            if (_index < 0) then {_manifest pushBack [_tag, _class, 1]} else {
                private _entry = _manifest select _index;
                _entry set [2, (_entry select 2) + 1];
            };
        } forEach _classes;
    };
} forEach _resolved;
if (_mineCount == 0) exitWith {[]};
_manifest
