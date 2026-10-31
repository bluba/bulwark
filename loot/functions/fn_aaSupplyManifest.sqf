// Public disposable launcher classes auto-load via CBA when equipped. No loose missiles.
private _stock = [
    ["weapon", "PSZ_Grom", 3],
    ["weapon", "CUP_launch_Igla", 3],
    ["backpack", "B_Carryall_mcamo", 2],
    ["magazine", "SmokeShell", 4],
    ["weapon", "Binocular", 1]
];
private _valid = true;
{
    _x params ["_tag", "_class", "_count"];
    private _root = switch (_tag) do {case "weapon": {"CfgWeapons"}; case "backpack": {"CfgVehicles"}; default {"CfgMagazines"}};
    private _cfg = configFile >> _root >> _class;
    if (!isClass _cfg) exitWith {_valid = false};
    if (_tag == "weapon" && {getNumber (_cfg >> "type") != (if (_class == "Binocular") then {4096} else {4})}) exitWith {_valid = false};
    if (_tag == "magazine" && {getNumber (_cfg >> "count") <= 0 ||
        {!isClass (configFile >> "CfgAmmo" >> getText (_cfg >> "ammo"))}}) exitWith {_valid = false};
} forEach _stock;
if (!_valid || {isNil "BIS_fnc_compatibleMagazines"} || {isNil "CBA_fnc_firedDisposable"}) exitWith {[]};
// Validate the real firing version of the disposable, not its fake inventory magazine.
{
    _x params ["_launcher", "_magazine"];
    private _compatible = (_launcher call BIS_fnc_compatibleMagazines) apply {toLowerANSI _x};
    private _magCfg = configFile >> "CfgMagazines" >> _magazine;
    if (!(toLowerANSI _magazine in _compatible) || {getNumber (_magCfg >> "count") != 1} ||
        {!isClass (configFile >> "CfgAmmo" >> getText (_magCfg >> "ammo"))}) exitWith {_valid = false};
} forEach [["PSZ_Grom_Base", "PSZ_Grom_AA"], ["CUP_launch_Igla_Loaded", "CUP_Igla_M"]];
if (!_valid) exitWith {[]};
_stock
