// Server transaction: clients choose an ID, never stock, family, class or price.
params [["_player", objNull, [objNull]], ["_id", -1, [0]]];
if (!([_player, true] call bulwark_fnc_validCaller) || {!finite _id} ||
    {side group _player != west} || {_player isKindOf "HeadlessClient_F"}) exitWith {objNull};
private _catalogue = missionNamespace getVariable ["BULWARK_SUPPLYITEMS", []];
private _index = _catalogue findIf {(_x select 3) == _id};
if (_index < 0) exitWith {objNull};
private _item = _catalogue select _index;
private _price = _item select 0;
private _family = _item select 2;
private _keys = [_family] call loot_fnc_supplyFamily;
if (_keys isEqualTo [] || {!(_price isEqualType 0)} || {!finite _price} ||
    {_price <= 0} || {_price != floor _price}) exitWith {objNull};
private _object = objNull;
private _message = "";
isNil {
    if (!(missionNamespace getVariable ["runMissionLoop", true]) ||
        {missionNamespace getVariable ["missionExtract", false]}) exitWith {_message = "Supplies are unavailable while the mission is ending."};
    if (!(missionNamespace getVariable [_keys select 4, true])) exitWith {_message = "This supply family is disabled."};
    if (_player getVariable ["buildItemHeld", false]) exitWith {_message = "You are already carrying an object."};
    private _balance = _player getVariable ["killPoints", 0];
    if (_balance < _price) exitWith {_message = "Not enough points."};
    private _class = missionNamespace getVariable [_keys select 6, "Box_NATO_Equip_F"];
    if !(_class isEqualType "") exitWith {_message = "Invalid supply crate configuration."};
    private _manifest = [_family] call loot_fnc_supplyManifest;
    private _mass = [_manifest] call loot_fnc_supplyMass;
    private _cfg = configFile >> "CfgVehicles" >> _class;
    if (_mass <= 0) exitWith {_message = "No valid stock is available under the current loot settings."};
    if (!isClass _cfg || {!(_class isKindOf ["ReammoBox_F", configFile >> "CfgVehicles"])} ||
        {_class isKindOf ["Box_NATO_Support_F", configFile >> "CfgVehicles"]} ||
        {getNumber (_cfg >> "maximumLoad") < _mass}) exitWith {_message = "The supply crate class is unavailable or too small."};
    private _radius = 0.8;
    _object = createVehicle [_class, _player getPos [_radius + 3, getDir _player], [], 0, "CAN_COLLIDE"];
    if (isNull _object) exitWith {_message = "The supply crate could not be created."};
    clearItemCargoGlobal _object;
    clearMagazineCargoGlobal _object;
    clearWeaponCargoGlobal _object;
    clearBackpackCargoGlobal _object;
    {
        _x params ["_tag", "_cargoClass", "_count"];
        switch (_tag) do {
            case "item": {_object addItemCargoGlobal [_cargoClass, _count]};
            case "magazine": {_object addMagazineCargoGlobal [_cargoClass, _count]};
            case "backpack": {_object addBackpackCargoGlobal [_cargoClass, _count]};
        };
    } forEach _manifest;
    _object setVariable ["bw_supplyPurchase", _family, true];
    _object setVariable ["bw_supplyManifest", _manifest];
    _object setVariable ["shopPrice", _price, true];
    _object setVariable ["Radius", _radius, true];
    _object setVariable ["bw_purchaseOwner", getPlayerUID _player, true];
    // No temporary-cache ID, world marker, lifetime, worker or flight is registered.
    _player setVariable ["killPoints", _balance - _price, true];
    _player setVariable ["buildItemHeld", true, true];
};
if (_message != "") then {[_message] remoteExecCall ["hint", _player]};
if (!isNull _object) then {
    [_object, _player, 0.8, 0] remoteExecCall ["bulwark_fnc_receivePurchase", _player];
    [] remoteExecCall ["killPoints_fnc_updateHud", _player];
};
_object
