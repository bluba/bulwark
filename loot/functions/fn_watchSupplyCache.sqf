// One server worker owns placement and then monitors only its tracked crate.
params ["_id", ["_family", "medical"]];
if (!isServer || {isRemoteExecuted} || {!canSuspend}) exitWith {};
private _keys = [_family] call loot_fnc_supplyFamily;
if (_keys isEqualTo []) exitWith {};
_keys params ["_recordKey", "_attemptKey", "_resultKey", "_statusKey", "_enabledKey", "_chanceKey", "_classKey"];
private _record = missionNamespace getVariable [_recordKey, createHashMap];
if ((_record getOrDefault ["id", -1]) != _id) exitWith {};
private _wave = _record get "wave";
private _anchor = _record get "anchorObject";
private _origin = _record get "anchorPosition";
private _life = missionNamespace getVariable ["BW_SUPPLY_LIFETIME", 180];
private _relocation = missionNamespace getVariable ["BW_SUPPLY_RELOCATION", 75];
private _class = missionNamespace getVariable [_classKey, "Box_NATO_Equip_F"];
if !(_class isEqualType "") exitWith {[_id, "invalidCrateClass", _family] call loot_fnc_endSupplyCache};
private _manifest = [_family] call loot_fnc_supplyManifest;
private _cfg = configFile >> "CfgVehicles" >> _class;
private _mass = 0;
private _validCargo = true;
{
    if (!(_x isEqualType []) || {count _x != 3}) exitWith {_validCargo = false};
    _x params ["_tag", "_cargoClass", "_count"];
    if (!(_tag in ["item", "magazine"]) || {!(_cargoClass isEqualType "")} ||
        {!(_count isEqualType 0)} || {!finite _count} || {_count <= 0} || {_count != floor _count}) exitWith {_validCargo = false};
    private _cargoCfg = configFile >> (if (_tag == "item") then {"CfgWeapons"} else {"CfgMagazines"}) >> _cargoClass;
    if (!isClass _cargoCfg) exitWith {_validCargo = false};
    private _entryMass = if (_tag == "item") then {getNumber (_cargoCfg >> "ItemInfo" >> "mass")} else {getNumber (_cargoCfg >> "mass")};
    if (_entryMass <= 0) exitWith {_validCargo = false};
    _mass = _mass + _count * _entryMass;
} forEach _manifest;
if (!_validCargo || {_manifest isEqualTo []} || {!(_life isEqualType 0) || {!finite _life} || {_life <= 0} || {_life > 600}} ||
    {!(_relocation isEqualType 0) || {!finite _relocation} || {_relocation <= 0} || {_relocation > 100}} ||
    {!isClass _cfg} || {!(_class isKindOf ["ReammoBox_F", configFile >> "CfgVehicles"])} ||
    {_class isKindOf ["Box_NATO_Support_F", configFile >> "CfgVehicles"]} ||
    {getNumber (_cfg >> "maximumLoad") <= 0} || {_mass <= 0} ||
    {getNumber (_cfg >> "maximumLoad") < _mass}) exitWith {[_id, "invalidManifestOrConfig", _family] call loot_fnc_endSupplyCache};
private _site = [_origin, [_family] call loot_fnc_supplyExclusions] call loot_fnc_findSupplySite;
if (_site isEqualTo []) exitWith {[_id, "placementFailed", _family] call loot_fnc_endSupplyCache};
private _reserved = false;
private _conflict = false;
isNil {
    private _current = missionNamespace getVariable [_recordKey, createHashMap];
    _conflict = (([_family] call loot_fnc_supplyExclusions) findIf {_site distance2D _x < 20}) >= 0;
    if ((_current getOrDefault ["id", -1]) == _id && {[_wave] call bulwark_fnc_waveActive} &&
        {!_conflict} && {!isNull _anchor} && {_anchor isEqualTo bulwarkBox} && {_anchor distance2D _origin < _relocation}) then {
        _current set ["site", +_site];
        _current set ["class", _class];
        _current set ["manifest", _manifest];
        _current set ["relocation", _relocation];
        _current set ["state", "inbound"];
        _reserved = true;
    };
};
if (!_reserved) exitWith {[_id, if (_conflict) then {"placementConflict"} else {"placementCancelled"}, _family] call loot_fnc_endSupplyCache};
private _deliveryResult = [_id, _family] call loot_fnc_deliverSupplyCache;
if (_deliveryResult != "") exitWith {[_id, _deliveryResult, _family] call loot_fnc_endSupplyCache};
private _committed = false;
isNil {
    private _current = missionNamespace getVariable [_recordKey, createHashMap];
    private _crate = _current getOrDefault ["crate", objNull];
    if ((_current getOrDefault ["id", -1]) == _id && {[_wave] call bulwark_fnc_waveActive} &&
        {alive _crate} && {!isNull _anchor} && {_anchor isEqualTo bulwarkBox} && {_anchor distance2D _origin < _relocation}) then {
        clearItemCargoGlobal _crate;
        clearMagazineCargoGlobal _crate;
        clearWeaponCargoGlobal _crate;
        clearBackpackCargoGlobal _crate;
        {
            _x params ["_tag", "_cargoClass", "_count"];
            if (_tag == "item") then {_crate addItemCargoGlobal [_cargoClass, _count]} else {
                _crate addMagazineCargoGlobal [_cargoClass, _count];
            };
        } forEach _manifest;
        _crate enableSimulationGlobal false;
        _crate allowDamage true;
        _current set ["site", getPosATL _crate];
        _current set ["expiresAt", serverTime + _life];
        _current set ["state", "available"];
        missionNamespace setVariable [_statusKey, [_id, _crate, getPosATL _crate, serverTime + _life, _wave], true];
        missionNamespace setVariable [_keys select 7, [], true];
        _committed = true;
        diag_log format ["Bulwark %1 supply %2: landed in wave %3 at %4", _family, _id, _wave, getPosATL _crate];
    };
};
if (!_committed) exitWith {[_id, "landingPublicationCancelled", _family] call loot_fnc_endSupplyCache};
private _reason = "";
while {_reason == ""} do {
    _record = missionNamespace getVariable [_recordKey, createHashMap];
    if ((_record getOrDefault ["id", -1]) != _id) exitWith {};
    private _crate = _record get "crate";
    _reason = switch (true) do {
        case (!(missionNamespace getVariable ["runMissionLoop", false])): {"missionEnded"};
        case (missionNamespace getVariable ["missionExtract", false]): {"extraction"};
        case ((missionNamespace getVariable ["attkWave", -1]) != _wave): {"nextWave"};
        case (isNull _anchor || {!(_anchor isEqualTo bulwarkBox)} || {_anchor distance2D _origin >= _relocation}): {"relocated"};
        case (!alive _crate): {"destroyed"};
        case (!isNull (attachedTo _crate) || {!isNull (isVehicleCargo _crate)} || {_crate distance (_record get "site") > 2}): {"cacheMoved"};
        case (serverTime >= (_record get "expiresAt")): {"expired"};
        case (itemCargo _crate isEqualTo [] && {magazineCargo _crate isEqualTo []} &&
            {weaponCargo _crate isEqualTo []} && {backpackCargo _crate isEqualTo []} && {everyContainer _crate isEqualTo []}): {"empty"};
        default {""};
    };
    if (_reason == "") then {sleep 1};
};
if (_reason != "") then {[_id, _reason, _family] call loot_fnc_endSupplyCache};
