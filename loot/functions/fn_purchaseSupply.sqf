// Server transaction: clients choose an ID, never stock, family, class or price.
params [["_player", objNull, [objNull]], ["_id", -1, [0]]];
if (!([_player] call bulwark_fnc_validCaller) || {!finite _id}) exitWith {objNull};
if (!([_player, true] call bulwark_fnc_validCaller) || {side group _player != west} || {_player isKindOf "HeadlessClient_F"}) exitWith {
    [false, "Supply purchase unavailable for your current player state or location."] remoteExecCall ["bulwark_fnc_shopResult", _player];
    objNull
};
private _catalogue = missionNamespace getVariable ["BULWARK_SUPPLYITEMS", []];
private _index = _catalogue findIf {(_x select 3) == _id};
if (_index < 0) exitWith {[false, "Supply item unavailable."] remoteExecCall ["bulwark_fnc_shopResult", _player]; objNull};
private _item = _catalogue select _index;
private _price = _item select 0;
private _family = _item select 2;
private _keys = [_family] call loot_fnc_supplyFamily;
if (_keys isEqualTo [] || {!(_price isEqualType 0)} || {!finite _price} ||
    {_price <= 0} || {_price != floor _price}) exitWith {[false, "Invalid supply configuration."] remoteExecCall ["bulwark_fnc_shopResult", _player]; objNull};
private _object = objNull;
private _message = "";
private _transactionStart = diag_tickTime;
isNil {
    if (!(missionNamespace getVariable ["runMissionLoop", true]) ||
        {missionNamespace getVariable ["missionExtract", false]}) exitWith {_message = "Supplies are unavailable while the mission is ending."};
    if (!(missionNamespace getVariable [_keys select 4, true])) exitWith {_message = "This supply family is disabled."};
    if (_player getVariable ["buildItemHeld", false]) exitWith {_message = "You are already carrying an object."};
    private _balance = _player getVariable ["killPoints", 0];
    if (_balance < _price) exitWith {_message = "Not enough points."};
    private _class = missionNamespace getVariable [_keys select 6, "Box_NATO_Equip_F"];
    if !(_class isEqualType "") exitWith {_message = "Invalid supply crate configuration."};
    missionNamespace setVariable ["BW_SUPPLY_STOCK_ERROR", ""];
    private _manifest = [_family] call loot_fnc_supplyManifest;
    private _mass = [_manifest] call loot_fnc_supplyMass;
    private _cfg = configFile >> "CfgVehicles" >> _class;
    if (_mass <= 0) exitWith {
        private _reason = missionNamespace getVariable ["BW_SUPPLY_STOCK_ERROR", ""];
        if (_reason == "") then {_reason = "Stock is empty or cargo validation failed"};
        _message = format ["%1 crate unavailable: %2", _family, _reason];
        diag_log ("BULWARK SUPPLY: " + _message);
    };
    if (!isClass _cfg || {!(_class isKindOf ["ReammoBox_F", configFile >> "CfgVehicles"])} ||
        {_class isKindOf ["Box_NATO_Support_F", configFile >> "CfgVehicles"]}) exitWith {
        _message = format ["Supply crate class is unavailable or unsupported: %1", _class];
    };
    private _capacity = getNumber (_cfg >> "maximumLoad");
    // Packed drones/components can outweigh the vanilla box's inventory limit.
    // Size this purchased container for its validated, complete fixed kit.
    if (_family == "drone") then {_capacity = _capacity max (ceil _mass)};
    if (_capacity < _mass) exitWith {
        _message = format ["Supply crate %1 is too small: capacity %2, required %3", _class, _capacity, _mass];
    };
    private _radius = 0.8;
    // Stage away from the shop before any physics-enabled object can overlap it.
    _object = createVehicle [_class, [0, 0, 1000], [], 0, "CAN_COLLIDE"];
    if (isNull _object) exitWith {_message = "The supply crate could not be created."};
    _object enableSimulationGlobal false;
    _object setPhysicsCollisionFlag false;
    [_object, false] remoteExecCall ["setPhysicsCollisionFlag", 0, _object];
    clearItemCargoGlobal _object;
    clearMagazineCargoGlobal _object;
    clearWeaponCargoGlobal _object;
    clearBackpackCargoGlobal _object;
    if (_family == "drone") then {_object setMaxLoad _capacity};
    {
        _x params ["_tag", "_cargoClass", "_count"];
        switch (_tag) do {
            case "weapon": {_object addWeaponCargoGlobal [_cargoClass, _count]};
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
private _transactionMs = 1000 * (diag_tickTime - _transactionStart);
if (_transactionMs >= 50) then {
    diag_log format ["BULWARK PERF purchase: catalogue ID %1, transaction %2 ms", _id, _transactionMs];
};
if (!isNull _object) then {_message = format ["Purchased %1 for %2 points.", localize (_item select 1), _price]};
[!isNull _object, _message] remoteExecCall ["bulwark_fnc_shopResult", _player];
if (!isNull _object) then {
    ["record", "supply", _id] remoteExecCall ["bulwark_fnc_recentPurchases", _player];
    [_object, _player, 0.8, 0] remoteExecCall ["bulwark_fnc_receivePurchase", _player];
    [] remoteExecCall ["killPoints_fnc_updateHud", _player];
};
_object
