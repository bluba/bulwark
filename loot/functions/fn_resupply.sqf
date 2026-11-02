// An unscheduled server transaction serializes payment, capacity and cargo additions.
params [["_player",objNull,[objNull]],["_crate",objNull,[objNull]],["_revision",-1,[0]]];
if (!([_player,false] call bulwark_fnc_validCaller)) exitWith {false};
private _success = false;
private _message = "Resupply unavailable.";
isNil {
    if (isNull _crate || {!alive _crate} || {!alive _player} || {lifeState _player == "INCAPACITATED"} ||
        {side group _player != west} || {_player distance _crate > 5} ||
        {_crate getVariable ["buildItemHeld",true]} || {!isNull attachedTo _crate} ||
        {isNil {_crate getVariable "bw_supplyManifest"}}) exitWith {};
    if (!(missionNamespace getVariable ["runMissionLoop",true]) || {missionNamespace getVariable ["missionExtract",false]}) exitWith {};
    if (_revision != (_crate getVariable ["bw_resupplyRevision",0]) || {serverTime < (_crate getVariable ["bw_resupplyAfter",0])}) exitWith {_message = "This crate was just resupplied. Try again shortly."};
    private _family = _crate getVariable ["bw_supplyPurchase",""];
    private _keys = [_family] call loot_fnc_supplyFamily;
    if (_keys isEqualTo [] || {!(missionNamespace getVariable [_keys select 4,true])}) exitWith {};
    private _rows = BULWARK_SUPPLYITEMS select {(_x select 2) == _family};
    if (_rows isEqualTo []) exitWith {};
    private _price = _rows select 0 select 0;
    private _balance = _player getVariable ["killPoints",0];
    if (!finite _price || {_price <= 0} || {_price != floor _price}) exitWith {};
    if (_balance < _price) exitWith {_message = "Not enough points."};
    private _manifest = [_family] call loot_fnc_supplyManifest;
    private _mass = [_manifest] call loot_fnc_supplyMass;
    if (_mass <= 0) exitWith {_message = "Required supply equipment is unavailable."};
    if ((loadAbs _crate) + _mass > maxLoad _crate) exitWith {_message = "Not enough room for a full supply batch. Remove some equipment first."};
    {
        _x params ["_tag","_class","_count"];
        switch (_tag) do {
            case "weapon": {_crate addWeaponCargoGlobal [_class,_count]};
            case "item": {_crate addItemCargoGlobal [_class,_count]};
            case "magazine": {_crate addMagazineCargoGlobal [_class,_count]};
            case "backpack": {_crate addBackpackCargoGlobal [_class,_count]};
        };
    } forEach _manifest;
    _player setVariable ["killPoints",_balance - _price,true];
    _crate setVariable ["bw_resupplyRevision",_revision + 1,true];
    _crate setVariable ["bw_resupplyAfter",serverTime + 2];
    _success = true;
    _message = "Resupplied: one batch added.";
};
[_message] remoteExecCall ["hint",_player];
if (_success) then {[] remoteExecCall ["killPoints_fnc_updateHud",_player]};
_success
