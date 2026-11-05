// Only catalogue IDs cross the network; prices and classes come from the server.
params [["_player", objNull, [objNull]], ["_kind", "", [""]], ["_id", -1, [0]]];
if (!([_player] call bulwark_fnc_validCaller) || {!finite _id}) exitWith {};
if (!([_player, true] call bulwark_fnc_validCaller)) exitWith {
    [false, "Purchase rejected: stay alive and within 10 metres of the Bulwark."] remoteExecCall ["bulwark_fnc_shopResult", _player];
};
if (_kind == "supply") exitWith {[_player, _id] call loot_fnc_purchaseSupply};
private _catalogue = [];
private _idField = 7;
if (_kind == "build") then {_catalogue = BULWARK_BUILDITEMS};
if (_kind == "support" && {SUPPORTMENU}) then {_catalogue = BULWARK_SUPPORTITEMS; _idField = 3};
private _index = _catalogue findIf {(_x select _idField) == _id};
if (_index < 0) exitWith {[false, "Item unavailable. Support requires a satellite dish."] remoteExecCall ["bulwark_fnc_shopResult", _player]};
private _item = _catalogue select _index;
private _price = _item select 0;
private _class = _item select 2;
private _message = "";
private _purchased = false;
private _transactionStart = diag_tickTime;
isNil {
    private _balance = _player getVariable ["killPoints", 0];
    if (_balance < _price) exitWith {_message = "Not enough points."};
    if (_kind == "support") exitWith {
        if ((_item select 4) == 0) then {
            private _tickets = parseNumber _class;
            if (_tickets <= 0) exitWith {_message = "Invalid ticket item."};
            _player setVariable ["killPoints", _balance - _price, true];
            _purchased = true;
            [west, _tickets] call BIS_fnc_respawnTickets;
            [] spawn bulwark_fnc_refreshRespawns;
        } else {
            _player setVariable ["killPoints", _balance - _price, true];
            _purchased = true;
            [_player, _class] remoteExecCall ["BIS_fnc_addCommMenuItem", _player];
        };
    };
    if ((_item select 6) == 10) exitWith {_message = "Developer items are unavailable."};
    if (_player getVariable ["buildItemHeld", false]) exitWith {_message = "You are already carrying an object."};
    if (!isClass (configFile >> "CfgVehicles" >> _class)) exitWith {_message = "This item requires a mod that is not loaded."};
    // Stage away from players and structures before disabling physics.
    private _spawn = [0, 0, 1000];
    private _object = objNull;
    private _crew = [];
    private _group = grpNull;
    if (_class isKindOf "Man") then {
        _group = createGroup [west, true];
        _object = _group createUnit [_class, _spawn, [], 0, "NONE"];
        _crew = [_object];
    } else {
        if (_item select 5) then {
            private _result = [_spawn, 0, _class, west] call BIS_fnc_spawnVehicle;
            _object = _result select 0;
            _crew = _result select 1;
            _group = _result select 2;
        } else {_object = createVehicle [_class, _spawn, [], 0, "CAN_COLLIDE"]};
    };
    if (isNull _object) exitWith {_message = "The item could not be created."};
    _object enableSimulationGlobal false;
    _object setPhysicsCollisionFlag false;
    [_object, false] remoteExecCall ["setPhysicsCollisionFlag", 0, _object];
    _player setVariable ["killPoints", _balance - _price, true];
            _purchased = true;
    // Reserve immediately, before the client receives the placement callback.
    _player setVariable ["buildItemHeld", true, true];
    _object setVariable ["shopPrice", _price, true];
    _object setVariable ["Radius", _item select 4, true];
    _object setVariable ["bw_purchaseOwner", getPlayerUID _player, true];
    _object setVariable ["bw_aiRange", _item param [8, 50], true];
    _object setVariable ["bw_allyGroup", _group, true];
    {_x disableAI "PATH"; _x setVariable ["aiMode", "NonCQB", true]} forEach _crew;
    clearItemCargoGlobal _object;
    clearWeaponCargoGlobal _object;
    clearMagazineCargoGlobal _object;
    clearBackpackCargoGlobal _object;
    [_object, _player, _item select 4, _item select 3] remoteExecCall ["bulwark_fnc_receivePurchase", _player];
};
private _transactionMs = 1000 * (diag_tickTime - _transactionStart);
if (_transactionMs >= 50) then {
    diag_log format ["BULWARK PERF purchase: catalogue ID %1, transaction %2 ms", _id, _transactionMs];
};
if (_purchased) then {_message = format ["Purchased %1 for %2 points.", _item select 1, _price]};
[_purchased, _message] remoteExecCall ["bulwark_fnc_shopResult", _player];
[] remoteExecCall ["killPoints_fnc_updateHud", _player];

if (_purchased) then {["record", _kind, _id] remoteExecCall ["bulwark_fnc_recentPurchases", _player]};
