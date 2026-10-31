// Validate tagged stock before creating a paid crate. -1 means invalid/empty.
params ["_manifest"];
if (!(_manifest isEqualType []) || {_manifest isEqualTo []}) exitWith {-1};
private _valid = true;
private _mass = 0;
{
    if (!(_x isEqualType []) || {count _x != 3}) exitWith {_valid = false};
    _x params ["_tag", "_class", "_count"];
    if (!(_tag in ["item", "weapon", "magazine", "backpack"]) || {!(_class isEqualType "")} ||
        {!(_count isEqualType 0)} || {!finite _count} || {_count <= 0} || {_count != floor _count}) exitWith {_valid = false};
    private _root = switch (_tag) do {case "item": {"CfgWeapons"}; case "weapon": {"CfgWeapons"}; case "backpack": {"CfgVehicles"}; default {"CfgMagazines"}};
    private _cfg = configFile >> _root >> _class;
    if (!isClass _cfg) exitWith {_valid = false};
    if (_tag == "backpack" && {getNumber (_cfg >> "isBackpack") != 1}) exitWith {_valid = false};
    if (_tag == "weapon" && {!(getNumber (_cfg >> "type") in [1,2,4])}) exitWith {_valid = false};
    private _unitMass = switch (_tag) do {
        case "item": {getNumber (_cfg >> "ItemInfo" >> "mass")};
        case "weapon": {getNumber (_cfg >> "WeaponSlotsInfo" >> "mass")};
        default {getNumber (_cfg >> "mass")};
    };
    if (_unitMass < 0 || {!finite _unitMass}) exitWith {_valid = false};
    _mass = _mass + _count * _unitMass;
} forEach _manifest;
if (!_valid || {!finite _mass} || {_mass <= 0}) exitWith {-1};
_mass
