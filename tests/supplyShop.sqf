/* Disposable hosted editor only: [] execVM "tests\supplyShop.sqf";
   Normal mission loop stopped; living conscious WEST host not carrying an object.
   Real server transaction/cargo. Placement callback is temporarily replaced on
   this host; actual carrying/placing and remote ownership need multiplayer checks.
*/
if (!isServer || {!hasInterface} || {isRemoteExecuted} || {!canSuspend}) exitWith {};
if (missionNamespace getVariable ["runMissionLoop", false] ||
    {!alive player} || {lifeState player == "INCAPACITATED"} || {side group player != west} ||
    {player getVariable ["buildItemHeld", false]}) exitWith {diag_log "SUPPLY SHOP test needs an idle hosted WEST player with a free holding slot"};
private _names = ["BULWARK_SUPPLYITEMS","BW_SUPPLY_ENABLED","BW_ENGINEERING_ENABLED","BW_SUPPLY_CLASS","BW_ENGINEERING_CLASS","BW_SUPPLY_STOCK","BW_DRONE_SUPPLY_ENABLED","BW_DRONE_SUPPLY_CLASS",
    "LOOT_WHITELIST_MODE","LOOT_WHITELIST_ITEM","LOOT_WHITELIST_EXPLOSIVE","LOOT_BLACKLIST","runMissionLoop","missionExtract","buildPhase","attkWave","bulwarkBox",
    "bulwark_fnc_receivePurchase","BW_supplyShopTestReceived"];
private _saved = _names apply {[!isNil _x,missionNamespace getVariable [_x,false]]};
private _balance = player getVariable ["killPoints",0];
private _held = player getVariable ["buildItemHeld",false];
private _failures = [];
private _objects = [];
private _check = {params ["_ok","_label"]; if (!_ok) then {_failures pushBack _label; diag_log ("SUPPLY SHOP FAIL: " + _label)}};
private _waitCallback = {params ["_object"]; private _deadline = diag_tickTime + 5;
    waitUntil {sleep 0.05; (missionNamespace getVariable ["BW_supplyShopTestReceived",objNull]) isEqualTo _object || {diag_tickTime >= _deadline}};
    [(missionNamespace getVariable ["BW_supplyShopTestReceived",objNull]) isEqualTo _object,"placement callback acknowledged"] call _check;
};
private _anchor = createVehicle ["Land_HelipadEmpty_F",getPosATL player,[],0,"CAN_COLLIDE"];
bulwarkBox = _anchor; runMissionLoop = true; missionExtract = false; buildPhase = true; attkWave = 0;
BW_SUPPLY_ENABLED = true; BW_ENGINEERING_ENABLED = true;
BW_SUPPLY_CLASS = "Box_NATO_Equip_F"; BW_ENGINEERING_CLASS = "Box_NATO_Equip_F";
BW_SUPPLY_STOCK = [["FirstAidKit",6],["Medikit",1]];
BULWARK_SUPPLYITEMS = [[3000,"STR_BW_BUY_MEDICAL","medical",9001],[3000,"STR_BW_BUY_ENGINEERING","engineering",9002],[3000,"STR_BW_BUY_DRONES","drone",9003]];
LOOT_WHITELIST_MODE = 0; LOOT_BLACKLIST = []; LOOT_WHITELIST_ITEM = []; LOOT_WHITELIST_EXPLOSIVE = [];
bulwark_fnc_receivePurchase = {params ["_object"]; BW_supplyShopTestReceived = _object};
player setVariable ["killPoints",10000,true]; player setVariable ["buildItemHeld",false,true];
[isNull ([objNull,9001] call loot_fnc_purchaseSupply),"invalid caller rejected"] call _check;
[isNull ([player,9999] call loot_fnc_purchaseSupply),"unknown ID rejected"] call _check;
private _medical = [player,9001] call loot_fnc_purchaseSupply;
if (!isNull _medical) then {_objects pushBack _medical; [_medical] call _waitCallback};
[!isNull _medical && {player getVariable ["killPoints",0] == 7000} && {player getVariable ["buildItemHeld",false]},"medical charged once and holding slot reserved"] call _check;
if (!isNull _medical) then {
    private _cargo = getItemCargo _medical;
    private _classes = _cargo select 0; private _counts = _cargo select 1;
    [count _classes == 2 && {(_classes find "FirstAidKit") >= 0} && {(_classes find "Medikit") >= 0} &&
        {(_counts select (_classes find "FirstAidKit")) == 6} && {(_counts select (_classes find "Medikit")) == 1},"exact medical stock"] call _check;
    [(_medical getVariable ["bw_supplyCacheId",-1]) == -1 && {(_medical getVariable ["bw_supplyPurchase",""]) == "medical"},"normal placeable object, no temporary-cache identity"] call _check;
};
[isNull ([player,9002] call loot_fnc_purchaseSupply) && {player getVariable ["killPoints",0] == 7000},"repeat purchase while carrying cannot debit"] call _check;
player setVariable ["buildItemHeld",false,true]; buildPhase = false; attkWave = 1;
private _engineering = [player,9002] call loot_fnc_purchaseSupply;
if (!isNull _engineering) then {_objects pushBack _engineering; [_engineering] call _waitCallback};
[!isNull _engineering && {player getVariable ["killPoints",0] == 4000},"engineering purchase allowed during combat"] call _check;
if (!isNull _engineering) then {
    private _manifest = _engineering getVariable ["bw_supplyManifest",[]];
    {
        _x params ["_tag","_class","_count"];
        private _cargo = if (_tag == "item") then {getItemCargo _engineering} else {getMagazineCargo _engineering};
        private _index = (_cargo select 0) find _class;
        [_index >= 0 && {(_cargo select 1 select _index) == _count},"typed engineering stock matches its single manifest"] call _check;
    } forEach _manifest;
    [!((magazineCargo _engineering) isEqualTo []),"engineering has mine/grenade magazine cargo"] call _check;
};
player setVariable ["buildItemHeld",false,true];
LOOT_WHITELIST_MODE = 1;
[isNull ([player,9001] call loot_fnc_purchaseSupply) && {player getVariable ["killPoints",0] == 4000},"empty filtered stock cannot debit"] call _check;
LOOT_WHITELIST_MODE = 0; BW_SUPPLY_CLASS = "MissingSupplyCrate";
[isNull ([player,9001] call loot_fnc_purchaseSupply) && {player getVariable ["killPoints",0] == 4000},"unavailable class cannot debit"] call _check;
BW_SUPPLY_CLASS = "Box_NATO_Equip_F"; BW_SUPPLY_ENABLED = false;
[isNull ([player,9001] call loot_fnc_purchaseSupply) && {player getVariable ["killPoints",0] == 4000},"disabled family cannot debit"] call _check;
BW_SUPPLY_ENABLED = true; player setVariable ["killPoints",999,true];
[isNull ([player,9001] call loot_fnc_purchaseSupply) && {player getVariable ["killPoints",0] == 999},"insufficient points cannot debit"] call _check;
player setVariable ["killPoints",4000,true]; missionExtract = true;
[isNull ([player,9001] call loot_fnc_purchaseSupply) && {player getVariable ["killPoints",0] == 4000},"ending cannot debit"] call _check;
missionExtract = false; attkWave = 2; buildPhase = true;
[!([attkWave] call loot_fnc_startSupplyCache) && {!([attkWave,"engineering"] call loot_fnc_startSupplyCache)},"legacy automatic drops disabled"] call _check;
[alive _medical && {alive _engineering},"purchased crates survive wave/phase changes"] call _check;
player setVariable ["buildItemHeld",false,true];
private _second = [player,9001] call loot_fnc_purchaseSupply;
if (!isNull _second) then {_objects pushBack _second; [_second] call _waitCallback};
[!isNull _second && {player getVariable ["killPoints",0] == 1000},"another paid crate can be bought in the same wave"] call _check;
player setVariable ["buildItemHeld",false,true];
player setVariable ["killPoints",6000,true];
BW_DRONE_SUPPLY_CLASS = "B_supplyCrate_F"; BW_DRONE_SUPPLY_ENABLED = false;
[isNull ([player,9003] call loot_fnc_purchaseSupply) && {player getVariable ["killPoints",0] == 6000},"disabled drone supply cannot debit"] call _check;
BW_DRONE_SUPPLY_ENABLED = true;
private _droneStock = ["drone"] call loot_fnc_supplyManifest;
private _drones = [player,9003] call loot_fnc_purchaseSupply;
if (_droneStock isEqualTo []) then {
    [isNull _drones && {player getVariable ["killPoints",0] == 6000},"missing drone content cannot debit"] call _check;
} else {
    [!isNull _drones && {player getVariable ["killPoints",0] == 3000},"drone crate charged once"] call _check;
    if (!isNull _drones) then {
        _objects pushBack _drones; [_drones] call _waitCallback;
        {
            _x params ["_tag","_class","_count"];
            private _cargo = switch (_tag) do {case "item": {getItemCargo _drones}; case "backpack": {getBackpackCargo _drones}; default {getMagazineCargo _drones}};
            private _index = (_cargo select 0) find _class;
            [_index >= 0 && {(_cargo select 1 select _index) == _count},"drone kit preserves typed cargo quantities"] call _check;
        } forEach _droneStock;
    };
};
{deleteVehicle _x} forEach _objects;
deleteVehicle _anchor;
player setVariable ["killPoints",_balance,true]; player setVariable ["buildItemHeld",_held,true];
{
    private _value = _saved select _forEachIndex;
    if (_value select 0) then {missionNamespace setVariable [_x,_value select 1]} else {missionNamespace setVariable [_x,nil]};
} forEach _names;
[] call killPoints_fnc_updateHud;
diag_log format ["SUPPLY SHOP tests complete: %1 failures %2",count _failures,_failures];
