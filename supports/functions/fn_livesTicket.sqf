// Compatibility entry point: resolve a server catalogue item, never trust a client price.
params [["_player", objNull, [objNull]], ["_ticketType", "", [""]]];
if (!([_player, true] call bulwark_fnc_validCaller)) exitWith {};
private _index = BULWARK_SUPPORTITEMS findIf {(_x select 2) == _ticketType && {(_x select 4) == 0}};
if (_index >= 0) then {
    [_player, "support", (BULWARK_SUPPORTITEMS select _index) select 3] call killPoints_fnc_purchase;
};
