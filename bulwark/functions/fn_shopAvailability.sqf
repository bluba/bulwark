// UI guidance only: the server remains authoritative for every transaction.
params [["_entry", []]];
if (_entry isEqualTo []) exitWith {"Select an item."};
_entry params ["_kind", "_id", "_price", "_label", "_class", "_category"];
if (!alive player || {lifeState player == "INCAPACITATED"}) exitWith {"You must be alive and able to act."};
if (isNil "bulwarkBox" || {player distance bulwarkBox > 10}) exitWith {"Move closer to the Bulwark."};
if (_kind == "support" && {!(missionNamespace getVariable ["SUPPORTMENU", false])}) exitWith {"Find a satellite dish to unlock support."};
if (_kind != "support" && {player getVariable ["buildItemHeld", false]}) exitWith {"Place your current item first."};
if (_kind == "build" && {_category == 10}) exitWith {"Developer items are unavailable."};
if (_kind == "build" && {!isClass (configFile >> "CfgVehicles" >> _class)}) exitWith {"Required mod is not loaded."};
private _reason = "";
if (_kind == "supply") then {
    private _keys = [_class] call loot_fnc_supplyFamily;
    if (_keys isEqualTo []) then {_reason = "Supply configuration unavailable."} else {
        if (!(missionNamespace getVariable [_keys select 4, true])) then {_reason = "This supply family is disabled."};
    };
    if (!(missionNamespace getVariable ["runMissionLoop", true]) || {missionNamespace getVariable ["missionExtract", false]}) then {_reason = "Supplies are unavailable while the mission is ending."};
};
if (_reason != "") exitWith {_reason};
private _balance = player getVariable ["killPoints", 0];
if (_price > _balance) exitWith {format ["Need %1 more points.", _price - _balance]};
""
