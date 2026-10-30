if (((_this select 0) getVariable ["bw_supplyCacheId", -1]) >= 0) exitWith {};
if (((_this select 0) getVariable ["bw_fpvId", -1]) >= 0) exitWith {};
_object = _this select 0;
_player = _this select 1;

_shopPrice = _object getVariable ["shopPrice", 0];

//hint "sold for " + _shopPrice;

//[_player, _shopPrice] call killPoints_fnc_add;

deleteVehicle (_object);
