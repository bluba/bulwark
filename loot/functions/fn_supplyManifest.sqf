// Tagged cargo format shared by supply families; no player-inventory scanning.
params [["_family", "medical"]];
if (_family == "antiair") exitWith {[] call loot_fnc_aaSupplyManifest};
if (_family == "antitank") exitWith {[] call loot_fnc_atSupplyManifest};
if (_family == "drone") exitWith {[] call loot_fnc_droneSupplyManifest};
if (_family == "engineering") exitWith {[] call loot_fnc_engineeringManifest};
if (_family != "medical") exitWith {[]};
private _profile = missionNamespace getVariable ["BW_SUPPLY_STOCK", [["FirstAidKit", 6], ["Medikit", 1]]];
private _mode = missionNamespace getVariable ["LOOT_WHITELIST_MODE", 0];
private _blacklist = missionNamespace getVariable ["LOOT_BLACKLIST", []];
private _whitelist = missionNamespace getVariable ["LOOT_WHITELIST_ITEM", []];
if !(_profile isEqualType [] && {_blacklist isEqualType []} && {_whitelist isEqualType []}) exitWith {[]};
if !(_mode in [0, 1, 2]) exitWith {[]};
private _manifest = [];
private _seen = [];
{
    if (_x isEqualType [] && {count _x == 2}) then {
        _x params ["_class", "_count"];
        if (_class isEqualType "" && {_count isEqualType 0} && {finite _count}) then {
            private _cap = switch (_class) do {case "FirstAidKit": {6}; case "Medikit": {1}; default {0}};
            private _cfg = configFile >> "CfgWeapons" >> _class;
            if (_count > 0 && {_count == floor _count} && {_count <= _cap} &&
                {!(_class in _seen)} && {!(_class in _blacklist)} &&
                {_mode != 1 || {_class in _whitelist}} && {isClass _cfg} &&
                {getNumber (_cfg >> "ItemInfo" >> "type") in [401, 619]}) then {
                _manifest pushBack ["item", _class, _count];
                _seen pushBack _class;
            };
        };
    };
} forEach _profile;
_manifest
