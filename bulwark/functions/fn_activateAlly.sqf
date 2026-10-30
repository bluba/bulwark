params [["_object", objNull, [objNull]], ["_buyer", objNull, [objNull]]];
if (!([_buyer] call bulwark_fnc_validCaller) || {isNull _object} ||
    {_object getVariable ["bw_purchaseOwner", ""] != getPlayerUID _buyer}) exitWith {};
private _group = _object getVariable ["bw_allyGroup", grpNull];
if (isNull _group) exitWith {};
[_group, _object, _buyer] call bulwark_fnc_followBulwark;
