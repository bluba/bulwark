// Approved fixed kit. Never substitute ammunition or sell a partial loadout.
private _stock = [
    ["weapon", "PSZ_RPG7V", 2],
    ["magazine", "PSZ_PG7VR_THEAT", 6],
    ["weapon", "PSZ_Spike_LR", 1],
    ["magazine", "PSZ_Spike_THEAT", 2],
    ["backpack", "B_Carryall_mcamo", 2],
    ["magazine", "SmokeShell", 4]
];
private _valid = true;
{
    _x params ["_tag", "_class", "_count"];
    private _root = switch (_tag) do {case "weapon": {"CfgWeapons"}; case "backpack": {"CfgVehicles"}; default {"CfgMagazines"}};
    private _cfg = configFile >> _root >> _class;
    if (!isClass _cfg) exitWith {_valid = false};
    if (_tag == "weapon" && {getNumber (_cfg >> "type") != 4}) exitWith {_valid = false};
    if (_tag == "magazine" && {getNumber (_cfg >> "count") <= 0 ||
        {!isClass (configFile >> "CfgAmmo" >> getText (_cfg >> "ammo"))}}) exitWith {_valid = false};
} forEach _stock;
if (!_valid || {isNil "BIS_fnc_compatibleMagazines"}) exitWith {[]};
{
    _x params ["_launcher", "_magazine"];
    private _compatible = (_launcher call BIS_fnc_compatibleMagazines) apply {toLowerANSI _x};
    if !(toLowerANSI _magazine in _compatible) exitWith {_valid = false};
} forEach [["PSZ_RPG7V", "PSZ_PG7VR_THEAT"], ["PSZ_Spike_LR", "PSZ_Spike_THEAT"]];
if (!_valid) exitWith {[]};
_stock
