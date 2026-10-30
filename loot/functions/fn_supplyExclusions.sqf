// At most one other family's site. Includes a site reserved before publication.
params [["_family", "medical"]];
private _sites = [];
{
    if (_x != _family) then {
        private _keys = [_x] call loot_fnc_supplyFamily;
        private _record = missionNamespace getVariable [_keys select 0, createHashMap];
        private _site = _record getOrDefault ["site", []];
        if (count _site == 3) then {_sites pushBack (+_site)};
    };
} forEach ["medical", "engineering"];
_sites
